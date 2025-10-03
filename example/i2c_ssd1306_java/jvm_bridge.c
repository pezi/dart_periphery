#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Define constants for error codes
#define JVM_CREATION_OK 0
#define JVM_CREATION_FAILED 1
#define JAVA_CLASS_NOT_FOUND 2
#define JAVA_METHOD_NOT_FOUND 4
#define OBJECT_CREATION_FAILED 5

// Helper struct to hold the JNI environment and related information
struct JVMenv {
    JavaVM *jvm;            // Pointer to the Java Virtual Machine
    JNIEnv *env;            // Pointer to the JNI environment interface
    jclass cls;             // Reference to the Java class we want to use
    jmethodID mid_create;   // Method ID for the Java method 'createEmoji'
    jmethodID mid_script;   // Method ID for the Java method 'script'
    jobject obj;            // Instance of the Java class
};

struct JVMenv *globalJVMenv; // Global variable to store our JVM environment

// Function to initialize the Java Virtual Machine (JVM) environment
int initJVMenv() {
    // Set up JVM options (e.g., classpath)
    JavaVMOption options;
    options.optionString = "-Djava.class.path=.:./lib/bsh-2.0b4.jar"; // Adjust class path as needed

    // Configure JVM initialization arguments
    JavaVMInitArgs vm_args;
    vm_args.version = JNI_VERSION_1_8; // Specify the required JNI version (1.8)
    vm_args.nOptions = 1;              // Number of options being passed
    vm_args.options = &options;        // Pointer to the options array
    vm_args.ignoreUnrecognized = JNI_FALSE; // Do not ignore unrecognized options

    // Allocate memory for our global JVM environment struct
    globalJVMenv = malloc(sizeof(struct JVMenv));

    // Create the JVM; the JVM and JNI environment pointers are stored in our global struct
    jint res = JNI_CreateJavaVM(&globalJVMenv->jvm, (void **)&globalJVMenv->env, &vm_args);
    if (res != JNI_OK) {
        fprintf(stderr, "Failed to create JVM\n");
        return JVM_CREATION_FAILED;
    }

    // Define the Java class and method names/signatures to be used later
    const char *class_name = "at/flutterdev/EmojiBMPGenerator"; 

    // Method details for createEmoji (accepts a byte array and two ints, returns a String)
    const char *method_name_create = "createEmoji";
    const char *method_signature_create = "([BII)Ljava/lang/String;";

    // Method details for script (accepts a String, returns a String)
    const char *method_name_script = "script";
    const char *method_signature_script = "(Ljava/lang/String;)Ljava/lang/String;";

    // Look up the Java class using its fully-qualified name
    globalJVMenv->cls = (*globalJVMenv->env)->FindClass(globalJVMenv->env, class_name);
    if (globalJVMenv->cls == NULL) {
        fprintf(stderr, "Failed to find Java class %s\n", class_name);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        return JAVA_CLASS_NOT_FOUND;
    }

    // Find the static method 'createEmoji' in the Java class with the specified signature
    globalJVMenv->mid_create = (*globalJVMenv->env)->GetStaticMethodID(globalJVMenv->env, globalJVMenv->cls, method_name_create, method_signature_create);
    if (globalJVMenv->mid_create == NULL) {
        fprintf(stderr, "Failed to find method %s with signature %s\n", method_name_create, method_signature_create);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        return JAVA_METHOD_NOT_FOUND;
    }

    // Find the static method 'script' in the Java class with the specified signature
    globalJVMenv->mid_script = (*globalJVMenv->env)->GetStaticMethodID(globalJVMenv->env, globalJVMenv->cls, method_name_script, method_signature_script);
    if (globalJVMenv->mid_script == NULL) {
        fprintf(stderr, "Failed to find method %s with signature %s\n", method_name_script, method_signature_script);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        return JAVA_METHOD_NOT_FOUND;
    }

    // No need to allocate object for static methods
    globalJVMenv->obj = NULL;

    return JVM_CREATION_OK; // Initialization successful
}

// Function to free resources and destroy the JVM environment
void freeJVMenv() {
    if (globalJVMenv != NULL) {
        if (globalJVMenv->jvm != NULL) {
            (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        }
        free(globalJVMenv);
        globalJVMenv = NULL;
    }
}

// Function to call the Java 'createEmoji' method which takes a byte array, two ints and returns a String
const char *call_create_emoji(const char *input, int height, int offset) {
    // Convert the C-string input to a Java byte array
    int len = strlen(input);
    jbyteArray j_bytes = (jbyteArray)(*globalJVMenv->env)->NewByteArray(globalJVMenv->env, len);
    if (j_bytes == NULL) {
        fprintf(stderr, "Failed to create Java byte array from input\n");
        freeJVMenv();
        return NULL;
    }

    // Copy the content of the input C-string into the Java byte array
    (*globalJVMenv->env)->SetByteArrayRegion(globalJVMenv->env, j_bytes, 0, len, (jbyte *)input);    

    // Call the static Java method 'createEmoji'
    jstring j_output = (jstring)(*globalJVMenv->env)->CallStaticObjectMethod(globalJVMenv->env, globalJVMenv->cls, globalJVMenv->mid_create, j_bytes, height, offset);
    if (j_output == NULL) {
        fprintf(stderr, "Java method returned NULL\n");
        freeJVMenv();
        return NULL;
    }

    // Convert the returned Java String to a C-string (UTF-8)
    const char *output = (*globalJVMenv->env)->GetStringUTFChars(globalJVMenv->env, j_output, NULL);
    if (output == NULL) {
        fprintf(stderr, "Failed to convert Java string to C string\n");
        freeJVMenv();
        return NULL;
    }

    // Duplicate the output into a new C-string so it can be freed independently later
    char *result = strdup(output);

    // Release the Java string memory now that we have copied it
    (*globalJVMenv->env)->ReleaseStringUTFChars(globalJVMenv->env, j_output, output);

    return result; // Return the duplicated C-string
}

// Function to call the Java 'script' method which takes and returns a String
const char *call_create_script(const char *input) {
    // Convert the C-string input into a Java String
    jstring j_input = (*globalJVMenv->env)->NewStringUTF(globalJVMenv->env, input);
    if (j_input == NULL) {
        fprintf(stderr, "Failed to create Java string from input\n");
        freeJVMenv();
        return NULL;
    }

    // Call the static Java method 'script'
    jstring j_output = (jstring)(*globalJVMenv->env)->CallStaticObjectMethod(globalJVMenv->env, globalJVMenv->cls, globalJVMenv->mid_script, j_input);
    if (j_output == NULL) {
        fprintf(stderr, "Java method returned NULL\n");
        freeJVMenv();
        return NULL;
    }

    // Convert the returned Java String to a C-string
    const char *output = (*globalJVMenv->env)->GetStringUTFChars(globalJVMenv->env, j_output, NULL);
    if (output == NULL) {
        fprintf(stderr, "Failed to convert Java string to C string\n");
        freeJVMenv();
        return NULL;
    }

    // Duplicate the output so that the returned pointer remains valid after releasing the Java string
    char *result = strdup(output);

    // Release the Java string
    (*globalJVMenv->env)->ReleaseStringUTFChars(globalJVMenv->env, j_output, output);

    return result; // Return the duplicated string
}

// Main entry point of the program
int main() {
    // Initialize the JVM environment
    if (initJVMenv() == JVM_CREATION_OK) {   
        // Print a simple message from C to confirm the start of execution
        printf("c: 🐵💩⚓\n\n");

        // Call the Java method 'createEmoji' with specific parameters and print the result
        const char *output = call_create_emoji("🐵💩⚓", 64, 10);
        printf("Java method returned: %s\n", output);
        free((void *)output); // Free the duplicated string returned by call_create_emoji

        // Call the Java method 'createEmoji' with a different input and print the result
        const char *output1 = call_create_emoji("⚓", 64, 10);
        printf("Java method returned: %s\n", output1);
        free((void *)output1); // Free the duplicated string

        // Clean up by freeing the JVM environment and all associated resources
        freeJVMenv();
    }
}