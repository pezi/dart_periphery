#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// install_name_tool -add_rpath $JAVA_HOME/lib/server/ ./cjava
// install_name_tool -add_rpath /Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/lib/server/ ./cjava
// gcc  -o  calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin" -L"$JAVA_HOME/lib/server" -ljvm   -o cjava calljava.c
//  gcc  -o  calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux"    -o cjava calljava.c -L"$JAVA_HOME/lib/server" -ljvm
// export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
// export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.
// javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java
// https://hildstrom.com/projects/2012/10/jni/index.html

struct JVMenv
{
    JavaVM *jvm;
    JNIEnv *env;
    jclass cls;
    jmethodID midCreate;
    jobject objCreate;
    jmethodID midScript;
    jobject obj;
};

struct JVMenv *globalJVMenv;

void initJVMenv()
{
    // Initialize JVM options
    JavaVMOption options;
    options.optionString = "-Djava.class.path=.:./lib/bsh-2.0b4.jar"; // Adjust class path as needed

    // Set up JVM initialization arguments
    JavaVMInitArgs vm_args;
    vm_args.version = JNI_VERSION_1_8; // Specify the JNI version
    vm_args.nOptions = 1;
    vm_args.options = &options;
    vm_args.ignoreUnrecognized = JNI_FALSE;

    // Create the JVM
    globalJVMenv = malloc(sizeof(struct JVMenv));
    jint res = JNI_CreateJavaVM(&globalJVMenv->jvm, (void **)&globalJVMenv->env, &vm_args);
    if (res != JNI_OK)
    {
        fprintf(stderr, "Failed to create JVM\n");
        exit(EXIT_FAILURE);
    }

    // Define the Java class and method to call
    const char *class_name = "at/flutterdev/EmojiBMPGenerator"; // Replace with your Java class name

    const char *method_name_create = "createEmojiBMP"; // Replace with your Java method name
    const char *method_signature_create = "(Ljava/lang/String;II)Ljava/lang/String;";

    const char *method_name_script = "script"; // Replace with your Java method name
    const char *method_signature_script = "(Ljava/lang/String;)Ljava/lang/String;";

    // Find the Java class
    globalJVMenv->cls = (*globalJVMenv->env)->FindClass(globalJVMenv->env, class_name);
    if (globalJVMenv->cls == NULL)
    {
        fprintf(stderr, "Failed to find Java class %s\n", class_name);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    // Find the Java method create
    globalJVMenv->midCreate = (*globalJVMenv->env)->GetStaticMethodID(globalJVMenv->env, globalJVMenv->cls, method_name_create, method_signature_create);
    if (globalJVMenv->midCreate == NULL)
    {
        fprintf(stderr, "Failed to find method %s with signature %s\n", method_name_create, method_signature_create);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    // Find the Java method create
    globalJVMenv->midScript = (*globalJVMenv->env)->GetStaticMethodID(globalJVMenv->env, globalJVMenv->cls, method_name_script, method_signature_script);
    if (globalJVMenv->midScript == NULL)
    {
        fprintf(stderr, "Failed to find method %s with signature %s\n", method_name_script, method_signature_script);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    // create object
    globalJVMenv->obj = (*globalJVMenv->env)->AllocObject(globalJVMenv->env, globalJVMenv->cls);
    if (globalJVMenv->obj == NULL)
    {
        fprintf(stderr, "Failed to allocate Java object\n");
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }
}

void freeJVMenv() {
    (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
}

// Function to call a Java method that accepts and returns a String
const char *call_create_emoji(const char *input, int heigth, int offset)
{
    // Create a new Java string from the C string input
    jstring j_input = (*globalJVMenv->env)->NewStringUTF(globalJVMenv->env, input);
    if (j_input == NULL)
    {
        fprintf(stderr, "Failed to create Java string from input\n");
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    
    // Call the Java method
    jstring j_output = (jstring)(*globalJVMenv->env)->CallObjectMethod(globalJVMenv->env,globalJVMenv->obj,globalJVMenv->midCreate, j_input, heigth, offset);
    if (j_output == NULL)
    {
        fprintf(stderr, "Java method returned NULL\n");
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    // Convert the Java string output to a C string
    const char *output = (*globalJVMenv->env)->GetStringUTFChars(globalJVMenv->env, j_output, NULL);
    if (output == NULL)
    {
        fprintf(stderr, "Failed to convert Java string to C string\n");
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    // Copy the output to a new C string
    char *result = strdup(output);

    // Release the Java string and destroy the JVM
    (*globalJVMenv->env)->ReleaseStringUTFChars(globalJVMenv->env, j_output, output);
  

    return result;
}

// Function to call a Java method that accepts and returns a String
const char *call_create_script(const char *input)
{
    // Create a new Java string from the C string input
    jstring j_input = (*globalJVMenv->env)->NewStringUTF(globalJVMenv->env, input);
    if (j_input == NULL)
    {
        fprintf(stderr, "Failed to create Java string from input\n");
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    
    // Call the Java method
    jstring j_output = (jstring)(*globalJVMenv->env)->CallObjectMethod(globalJVMenv->env,globalJVMenv->obj,globalJVMenv->midScript, j_input);
    if (j_output == NULL)
    {
        fprintf(stderr, "Java method returned NULL\n");
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    // Convert the Java string output to a C string
    const char *output = (*globalJVMenv->env)->GetStringUTFChars(globalJVMenv->env, j_output, NULL);
    if (output == NULL)
    {
        fprintf(stderr, "Failed to convert Java string to C string\n");
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        exit(EXIT_FAILURE);
    }

    // Copy the output to a new C string
    char *result = strdup(output);

    // Release the Java string and destroy the JVM
    (*globalJVMenv->env)->ReleaseStringUTFChars(globalJVMenv->env, j_output, output);
  

    return result;
}

int main()
{
    initJVMenv();
    const char *output = call_create_emoji("💩", 64, 10);
    printf("Java method returned: %s\n", output);
    free((void *)output); // Free the duplicated string

    const char *output1 = call_create_emoji("⚓", 64, 10);
    printf("Java method returned: %s\n", output1);
    free((void *)output1); // Free the duplicated string

    freeJVMenv();
    
}
