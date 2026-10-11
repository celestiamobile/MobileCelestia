// CelestiaAppCore+Locale.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import "CelestiaAppCore+Locale.h"

#include <celutil/fsutils.h>
#include <celutil/gettext.h>
#include <fmt/format.h>

NSString *LocalizedFilename(NSString *originalName)
{
    using namespace celestia::util;
    return [NSString stringWithUTF8String:LocaleFilename([originalName UTF8String]).string().c_str()];
}

NSString *LocalizedString(NSString *originalString, NSString *domain)
{
    if ([originalString length] == 0)
        return originalString;
    return [NSString stringWithUTF8String:dgettext([domain UTF8String], [originalString UTF8String])];
}

NSString *LocalizedStringContext(NSString *originalString, NSString *context, NSString *domain)
{
    if ([originalString length] == 0)
        return originalString;

    std::string auxStr = fmt::format("{}\004{}", [context UTF8String], [originalString UTF8String]);
    const char *aux = auxStr.c_str();
    const char *translation = dgettext([domain UTF8String], aux);
    if (translation == aux)
        return originalString;
    else
        return [NSString stringWithUTF8String:translation];
}
