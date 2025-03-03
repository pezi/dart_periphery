#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// install_name_tool -add_rpath $JAVA_HOME/lib/server/ ./cjava
// install_name_tool -add_rpath /Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/lib/server/ ./cjava
// gcc  -o  calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin" jvm_bridge.c   -L"$JAVA_HOME/lib/server" -ljvm
//  gcc  -o  calljava -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" calljava.c -L"$JAVA_HOME/lib/server" -ljvm
// export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
// export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:.
// javac -cp ./lib/bsh-2.0b4.jar at/flutterdev/EmojiBMPGenerator.java
// https://hildstrom.com/projects/2012/10/jni/index.html

#define JVM_CREATION_OK 0
#define JVM_CREATION_FAILED 1
#define JAVA_CLASS_NOT_FOUND 2
#define JAVA_METHOD_NOT_FOUND 4
#define OBJECT_CREATION_FAILED 5

//
struct JVMenv
{
    JavaVM *jvm;
    JNIEnv *env;
    jclass cls;
    jmethodID mid_create;
    jmethodID mid_script;
    jobject obj;
};

struct JVMenv *globalJVMenv;


int initJVMenv()
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
        return JVM_CREATION_FAILED;
    }

    // Define the Java class and method to call
    const char *class_name = "at/flutterdev/EmojiBMPGenerator"; // Replace with your Java class name

    const char *method_name_create = "createEmoji"; // Replace with your Java method name
    const char *method_signature_create = "(Ljava/lang/String;II)Ljava/lang/String;";

    const char *method_name_script = "script"; // Replace with your Java method name
    const char *method_signature_script = "(Ljava/lang/String;)Ljava/lang/String;";

    // Find the Java class
    globalJVMenv->cls = (*globalJVMenv->env)->FindClass(globalJVMenv->env, class_name);
    if (globalJVMenv->cls == NULL)
    {
        fprintf(stderr, "Failed to find Java class %s\n", class_name);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        return JAVA_CLASS_NOT_FOUND;
    }

    // Find the Java method create
    globalJVMenv->mid_create = (*globalJVMenv->env)->GetStaticMethodID(globalJVMenv->env, globalJVMenv->cls, method_name_create, method_signature_create);
    if (globalJVMenv->mid_create == NULL)
    {
        fprintf(stderr, "Failed to find method %s with signature %s\n", method_name_create, method_signature_create);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        return JAVA_METHOD_NOT_FOUND;
    }

    // Find the Java method create
    globalJVMenv->mid_script = (*globalJVMenv->env)->GetStaticMethodID(globalJVMenv->env, globalJVMenv->cls, method_name_script, method_signature_script);
    if (globalJVMenv->mid_script == NULL)
    {
        fprintf(stderr, "Failed to find method %s with signature %s\n", method_name_script, method_signature_script);
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        return JAVA_METHOD_NOT_FOUND;
    }

    // create object
    globalJVMenv->obj = (*globalJVMenv->env)->AllocObject(globalJVMenv->env, globalJVMenv->cls);
    if (globalJVMenv->obj == NULL)
    {
        fprintf(stderr, "Failed to allocate Java object\n");
        (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        return OBJECT_CREATION_FAILED;
    }
    return JVM_CREATION_OK;
}

void freeJVMenv()
{
    if (globalJVMenv != NULL)
    {
        if (globalJVMenv->jvm != NULL)
        {
            (*globalJVMenv->jvm)->DestroyJavaVM(globalJVMenv->jvm);
        }
        free(globalJVMenv);
        globalJVMenv = NULL;
    }
}

// Function to call a Java method that accepts and returns a String
const char *call_create_emoji(const char *input, int heigth, int offset)
{
    // Create a new Java string from the C string input
    jstring j_input = (*globalJVMenv->env)->NewStringUTF(globalJVMenv->env, input);
    if (j_input == NULL)
    {
        fprintf(stderr, "Failed to create Java string from input\n");
        freeJVMenv();
        return NULL;
    }

    // Call the Java method
    jstring j_output = (jstring)(*globalJVMenv->env)->CallObjectMethod(globalJVMenv->env, globalJVMenv->obj, globalJVMenv->mid_create, j_input, heigth, offset);
    if (j_output == NULL)
    {
        fprintf(stderr, "Java method returned NULL\n");
        freeJVMenv();
        return NULL;
    }

    // Convert the Java string output to a C string
    const char *output = (*globalJVMenv->env)->GetStringUTFChars(globalJVMenv->env, j_output, NULL);
    if (output == NULL)
    {
        fprintf(stderr, "Failed to convert Java string to C string\n");
        freeJVMenv();
        return NULL;
    }

    // Copy the output to a new C string
    char *result = strdup(output);

    // Release the Java string
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
        freeJVMenv();
        return NULL;
    }

    // Call the Java method
    jstring j_output = (jstring)(*globalJVMenv->env)->CallObjectMethod(globalJVMenv->env, globalJVMenv->obj, globalJVMenv->mid_script, j_input);
    if (j_output == NULL)
    {
        fprintf(stderr, "Java method returned NULL\n");
        freeJVMenv();
        return NULL;
    }

    // Convert the Java string output to a C string
    const char *output = (*globalJVMenv->env)->GetStringUTFChars(globalJVMenv->env, j_output, NULL);
    if (output == NULL)
    {
        fprintf(stderr, "Failed to convert Java string to C string\n");
        freeJVMenv();
        return NULL;
    }

    // Copy the output to a new C string
    char *result = strdup(output);

    // Release the Java string
    (*globalJVMenv->env)->ReleaseStringUTFChars(globalJVMenv->env, j_output, output);

    return result;
}

int main()
{
    if (initJVMenv() == 0)
    {
        const char *output = call_create_emoji("💩", 64, 10);
        printf("Java method returned: %s\n", output);
        free((void *)output); // Free the duplicated string

        const char *output1 = call_create_emoji("⚓", 64, 10);
        printf("Java method returned: %s\n", output1);
        free((void *)output1); // Free the duplicated string

        freeJVMenv();
    }
}
