// CEZZipUtils.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import "CEZZipUtils.h"

#include <zip.h>

#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

NSString *const CEZZipErrorDomain = @"Zip";
NSErrorUserInfoKey const CEZZipErrorContextPathKey = @"ContextPath";

@implementation CEZZipUtils

+ (BOOL)unzip:(NSString *)sourcePath destinationPath:(NSString *)destinationPath error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if (error != nullptr)
        *error = nil;

    std::string source = [sourcePath UTF8String];
    std::string destinationFolder = [destinationPath UTF8String];

    auto archive = zip_open(source.c_str(), 0, nullptr);
    if (!archive)
    {
        if (error != nullptr)
            *error = [NSError errorWithDomain:CEZZipErrorDomain code:CEZZipErrorCodeZip userInfo:nil];
        return NO;
    }

    zip_file_t *currentEntry = nullptr;
    bool hasZipError = false;
    bool hasSystemError = false;

    for (zip_int64_t i = 0; i < zip_get_num_entries(archive, 0); i += 1)
    {
        // TODO: Check cancellation
        struct zip_stat st;
        if (zip_stat_index(archive, i, 0, &st) != 0)
        {
            hasZipError = true;
            if (error != nullptr)
                *error = [NSError errorWithDomain:CEZZipErrorDomain code:CEZZipErrorCodeZip userInfo:nil];
            break;
        }

        std::filesystem::path name{ st.name };
        std::vector<std::string> components;

        for (auto const& component : name)
            components.push_back(component.string());

        bool isRegularFile = name.has_filename();
        std::filesystem::path currentDirectory = destinationFolder;

        for (int j = 0; j < components.size(); ++j)
        {
            const auto& component = components[j];
            if (component.empty())
                continue;

            // The last one is the filename for file entries, we don't create directory for it
            if (!isRegularFile || j != components.size() - 1)
            {
                currentDirectory = currentDirectory / component;
                std::error_code ec;
                bool exists = std::filesystem::exists(currentDirectory, ec);

                if (ec)
                {
                    hasSystemError = true;
                    if (error != nullptr)
                        *error = [NSError errorWithDomain:CEZZipErrorDomain code:CEZZipErrorCodeCreateDirectory userInfo:@{CEZZipErrorContextPathKey: [NSString stringWithUTF8String:currentDirectory.string().c_str()]}];
                    break;
                }

                if (!exists)
                {
                    bool success = std::filesystem::create_directory(currentDirectory, ec);
                    if (!success || ec)
                    {
                        hasSystemError = true;
                        if (error != nullptr)
                            *error = [NSError errorWithDomain:CEZZipErrorDomain code:CEZZipErrorCodeCreateDirectory userInfo:@{CEZZipErrorContextPathKey: [NSString stringWithUTF8String:currentDirectory.string().c_str()]}];
                        break;
                    }
                }
            }
        }

        if (hasSystemError)
            break;

        if (!isRegularFile)
            continue;

        currentEntry = zip_fopen_index(archive, i, 0);
        if (!currentEntry)
        {
            hasZipError = true;
            if (error != nullptr)
                *error = [NSError errorWithDomain:CEZZipErrorDomain code:CEZZipErrorCodeZip userInfo:nil];
            break;
        }

        std::filesystem::path filePath = currentDirectory / name.filename();
        std::ofstream file(filePath, std::ios::binary);
        if (!file.good())
        {
            hasSystemError = true;
            if (error != nullptr)
                *error = [NSError errorWithDomain:CEZZipErrorDomain code:CEZZipErrorCodeOpenFile userInfo:@{CEZZipErrorContextPathKey: [NSString stringWithUTF8String:filePath.string().c_str()]}];
            break;
        }

        zip_uint64_t bytesWritten = 0;
        const uint32_t bufferSize = 4096;
        char buffer[bufferSize];
        while (bytesWritten != st.size)
        {
            // TODO: Check cancellation
            auto bytesRead = zip_fread(currentEntry, buffer, bufferSize);
            if (bytesRead < 0)
            {
                hasZipError = true;
                if (error != nullptr)
                    *error = [NSError errorWithDomain:CEZZipErrorDomain code:CEZZipErrorCodeZip userInfo:nil];
                break;
            }

            if (!file.write(buffer, bytesRead).good())
            {
                hasSystemError = true;
                if (error != nullptr)
                    *error = [NSError errorWithDomain:CEZZipErrorDomain code:CEZZipErrorCodeWriteFile userInfo:@{CEZZipErrorContextPathKey: [NSString stringWithUTF8String:filePath.string().c_str()]}];
                break;
            }

            bytesWritten += bytesRead;
        }
        zip_fclose(currentEntry);
        currentEntry = nullptr;

        if (hasSystemError || hasZipError)
            break;
    }

    // Clean up
    if (currentEntry != nullptr)
        zip_fclose(currentEntry);
    zip_close(archive);

    return !hasSystemError && !hasZipError;
}

@end
