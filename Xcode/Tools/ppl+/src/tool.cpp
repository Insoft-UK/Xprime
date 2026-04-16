// The MIT License (MIT)
//
// Copyright (c) 2024-2025 Insoft.
//
// Created: 2025-12-19
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include "tool.hpp"

#include <string>
#include <vector>
#include <cstdlib>
#include <cstring>

#if defined(_WIN32)
    #include <windows.h>
#else
    #include <limits.h>
    #include <unistd.h>
    #include <spawn.h>
    #include <sys/wait.h>
#endif

#if defined(__APPLE__)
    #include <mach-o/dyld.h>
#endif

#if defined(__APPLE__) || defined(__linux__)
extern char **environ;
#endif

using namespace tool;

static std::string executableDir()
{
#ifdef DEBUG
    return "/usr/local/bin";
#endif
#if defined(_WIN32)

    char path[MAX_PATH];
    DWORD len = GetModuleFileNameA(nullptr, path, MAX_PATH);
    if (len == 0)
        return {};

    std::string fullPath(path, len);
    return fullPath.substr(0, fullPath.find_last_of("\\/"));

#elif defined(__APPLE__)

    uint32_t size = 0;
    _NSGetExecutablePath(nullptr, &size);

    std::string path(size, '\0');
    _NSGetExecutablePath(path.data(), &size);

    char resolved[PATH_MAX];
    if (!realpath(path.c_str(), resolved))
        return {};

    std::string fullPath(resolved);
    return fullPath.substr(0, fullPath.find_last_of('/'));

#elif defined(__linux__)

    char path[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", path, sizeof(path) - 1);
    if (len == -1)
        return {};

    path[len] = '\0';
    std::string fullPath(path);
    return fullPath.substr(0, fullPath.find_last_of('/'));

#else
    return {};
#endif
}


#if defined(_WIN32)

static std::string readPipe(HANDLE pipe)
{
    std::string out;
    char buffer[4096];
    DWORD read = 0;

    while (ReadFile(pipe, buffer, sizeof(buffer), &read, nullptr) && read)
        out.append(buffer, read);

    return out;
}

result_t tool::runTool(const std::string& command,
                       const std::vector<std::string>& arguments)
{
    std::string dir = executableDir();
    std::string cmd = "\"" + dir + "\\" + command + "\"";

    for (auto& a : arguments)
        cmd += " \"" + a + "\"";

    SECURITY_ATTRIBUTES sa{ sizeof(sa), nullptr, TRUE };
    HANDLE outRead, outWrite, errRead, errWrite;

    CreatePipe(&outRead, &outWrite, &sa, 0);
    CreatePipe(&errRead, &errWrite, &sa, 0);

    STARTUPINFOA si{};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdOutput = outWrite;
    si.hStdError  = errWrite;

    PROCESS_INFORMATION pi{};

    BOOL ok = CreateProcessA(
        nullptr,
        cmd.data(),
        nullptr, nullptr,
        TRUE,
        CREATE_NO_WINDOW,
        nullptr,
        nullptr,
        &si,
        &pi
    );

    CloseHandle(outWrite);
    CloseHandle(errWrite);

    result_t r{};

    if (!ok) {
        r.exitCode = -1;
        r.err = "CreateProcess failed";
        return r;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);

    DWORD code;
    GetExitCodeProcess(pi.hProcess, &code);
    r.exitCode = static_cast<int>(code);

    r.out = readPipe(outRead);
    r.err = readPipe(errRead);

    CloseHandle(outRead);
    CloseHandle(errRead);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    return r;
}

#else // POSIX

static std::string readFd(int fd)
{
    std::string result;
    char buffer[4096];

    ssize_t n;
    while ((n = read(fd, buffer, sizeof(buffer))) > 0) {
        result.append(buffer, n);
    }
    return result;
}


result_t tool::runTool(const std::string& command, const std::vector<std::string>& arguments)
{
    std::string dir  = executableDir();
    std::string tool = dir + "/" + command;

    // Pipes for stdout and stderr
    int outPipe[2];
    int errPipe[2];
    pipe(outPipe);
    pipe(errPipe);

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);

    // Redirect child's stdout -> outPipe[1]
    posix_spawn_file_actions_adddup2(&actions, outPipe[1], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&actions, errPipe[1], STDERR_FILENO);

    // Close unused fds in child
    posix_spawn_file_actions_addclose(&actions, outPipe[0]);
    posix_spawn_file_actions_addclose(&actions, errPipe[0]);

    // Build argv
    std::vector<char*> argv;
    argv.push_back(const_cast<char*>(tool.c_str()));
    for (const auto& arg : arguments)
        argv.push_back(const_cast<char*>(arg.c_str()));
    argv.push_back(nullptr);

    pid_t pid;
    int rc = posix_spawn(&pid, tool.c_str(), &actions, nullptr,
                         argv.data(), environ);

    // Parent doesn't write
    close(outPipe[1]);
    close(errPipe[1]);

    result_t result{};

    if (rc == 0) {
        result.out = readFd(outPipe[0]);
        result.err = readFd(errPipe[0]);

        int status;
        waitpid(pid, &status, 0);
        if (WIFEXITED(status))
            result.exitCode = WEXITSTATUS(status);
        else
            result.exitCode = -1;
    } else {
        result.exitCode = rc;
        result.err = std::strerror(rc);
    }

    close(outPipe[0]);
    close(errPipe[0]);

    posix_spawn_file_actions_destroy(&actions);
    return result;
}

#endif

