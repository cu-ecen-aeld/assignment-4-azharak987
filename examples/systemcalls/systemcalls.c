#include "systemcalls.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>  // for open

bool do_system(const char *cmd) {
    int ret = system(cmd);
    return WIFEXITED(ret) && WEXITSTATUS(ret) == 0;
}

bool do_exec(int count, ...) {
    va_list args;
    va_start(args, count);

    char *command[count + 1];
    int i;
    for (i = 0; i < count; i++) {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    if (command[0][0] != '/') {
        fprintf(stderr, "Error: Command must be specified with an absolute path.\n");
        return false;
    }

    pid_t pid = fork();
    if (pid == -1) {
        perror("Fork failed");
        return false;
    } else if (pid == 0) {
        // Close standard input, output, and error to prevent interference
        close(STDIN_FILENO);
        close(STDOUT_FILENO);
        close(STDERR_FILENO);

        execv(command[0], command);

        // execv will only return if there's an error
        perror("Execv failed");
        exit(EXIT_FAILURE);
    } else {
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }

    va_end(args);
}

bool do_exec_redirect(const char *outputfile, int count, ...) {
    va_list args;
    va_start(args, count);

    char *command[count + 1];
    int i;
    for (i = 0; i < count; i++) {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    pid_t pid = fork();
    if (pid == -1) {
        perror("Fork failed");
        return false;
    } else if (pid == 0) {
        int output_fd = open(outputfile, O_WRONLY | O_CREAT | O_TRUNC, 0666);
        if (output_fd == -1) {
            perror("Open failed");
            exit(EXIT_FAILURE);
        }

        // Redirect standard output to the output file
        if (dup2(output_fd, STDOUT_FILENO) == -1) {
            perror("Dup2 failed");
            exit(EXIT_FAILURE);
        }
        close(output_fd);

        // If the command doesn't have an absolute path, use execvp
        if (command[0][0] != '/') {
            execvp(command[0], command);
        } else {
            execv(command[0], command);
        }

        // execv/execvp will only return if there's an error
        perror("Execv/Execvp failed");
        exit(EXIT_FAILURE);
    } else {
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }

    va_end(args);
}
