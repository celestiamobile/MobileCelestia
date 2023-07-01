//
// CXCRenderResource.m
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CXCRenderResource.h"

@interface CXCRenderResource ()
@end

@implementation CXCRenderResource

- (instancetype)init {
    self = [super init];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _eglContext = EGL_NO_CONTEXT;
        _eglDisplay = EGL_NO_DISPLAY;
        _postprocessProgram = 0;
        _postprocessProgramVAO = 0;
        _postprocessProgramVBO = 0;
        _postprocessProgramTextureLocation = 0;
    }
    return self;
}

- (void)cleanup {
    [self cleanupGL];
    [self cleanupEGL];
}

- (BOOL)prepare {
    BOOL success = [self prepareEGL];
    if (!success)
        return NO;
    success = [self prepareGL];
    if (!success) {
        [self cleanupEGL];
        return NO;
    }
    return YES;
}

- (BOOL)prepareEGL {
    EGLAttrib displayAttribs[] = { EGL_NONE };
    _eglDisplay = eglGetPlatformDisplay(EGL_PLATFORM_ANGLE_ANGLE, NULL, displayAttribs);
    if (_eglDisplay == EGL_NO_DISPLAY) {
        NSLog(@"eglGetPlatformDisplay() returned error %d", eglGetError());
        [self cleanupEGL];
        return NO;
    }

    if (!eglInitialize(_eglDisplay, NULL, NULL)) {
        NSLog(@"eglInitialize() returned error %d", eglGetError());
        [self cleanupEGL];
        return NO;
    }

    EGLConfig config = 0;
    EGLint configAttribs[] =
    {
        EGL_BLUE_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_RED_SIZE, 8,
        EGL_DEPTH_SIZE, 24,
        EGL_NONE
    };
    EGLint numConfigs;
    if (!eglChooseConfig(_eglDisplay, configAttribs, &config, 1, &numConfigs)) {
        NSLog(@"eglChooseConfig() returned error %d", eglGetError());
        [self cleanupEGL];
        return NO;
    }

    EGLint ctxAttribs[] = { EGL_CONTEXT_MAJOR_VERSION, 2, EGL_CONTEXT_MINOR_VERSION, 0, EGL_NONE };
    _eglContext = eglCreateContext(_eglDisplay, config, EGL_NO_CONTEXT, ctxAttribs);
    if (_eglContext == EGL_NO_CONTEXT) {
        NSLog(@"eglCreateContext() returned error %d", eglGetError());
        [self cleanupEGL];
        return NO;
    }
    return YES;
}

- (BOOL)prepareGL {
    eglMakeCurrent(_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, _eglContext);
    if (![self prepareDegammaProgram]) {
        [self cleanupGL];
        return NO;
    }
    return YES;
}

- (NSString *)getShaderErrorLogForShader:(GLuint)shader {
    GLint logLength = 0;
    GLsizei charsWritten = 0;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength <= 0)
        return @"";
    char *log = (char *)malloc(logLength);
    glGetShaderInfoLog(shader, logLength, &charsWritten, log);
    NSString *nsLog = [NSString stringWithUTF8String:log];
    free(log);
    return nsLog;
}

- (NSString *)getProgramErrorLogForProgram:(GLuint)program {
    GLint logLength = 0;
    GLsizei charsWritten = 0;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength <= 0)
        return @"";
    char *log = (char *)malloc(logLength);
    glGetProgramInfoLog(program, logLength, &charsWritten, log);
    NSString *nsLog = [NSString stringWithUTF8String:log];
    free(log);
    return nsLog;
}

- (BOOL)prepareDegammaProgram {
    const char* vShaderSource =
        "attribute vec2 in_Position;\n"
        "attribute vec2 in_TexCoord;\n"
        "varying vec2 texCoord;\n"
        "void main()\n"
        "{\n"
        "    gl_Position = vec4(in_Position.xy, 0.0, 1.0);\n"
        "    texCoord = in_TexCoord.st;\n"
        "}";
    const char* fShaderSource =
        "precision mediump float;\n"
        "varying vec2 texCoord;\n"
        "uniform sampler2D tex;\n"
        "void main()\n"
        "{\n"
        "    gl_FragColor = texture2D(tex, texCoord);\n"
        "    gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(2.2));\n"
        "}\n";

    GLuint vShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vShader, 1, &vShaderSource, NULL);
    glCompileShader(vShader);

    GLint compiled;
    glGetShaderiv(vShader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        NSLog(@"Error compiling degamma vertex shader: %@", [self getShaderErrorLogForShader:vShader]);
        glDeleteShader(vShader);
        return NO;
    }

    GLuint fShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fShader, 1, &fShaderSource, NULL);
    glCompileShader(fShader);

    glGetShaderiv(fShader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        NSLog(@"Error compiling degamma fragment shader: %@", [self getShaderErrorLogForShader:fShader]);
        glDeleteShader(fShader);
        glDeleteShader(vShader);
        return NO;
    }

    _postprocessProgram = glCreateProgram();
    glAttachShader(_postprocessProgram, vShader);
    glAttachShader(_postprocessProgram, fShader);
    glBindAttribLocation(_postprocessProgram, 0, "in_Position");
    glBindAttribLocation(_postprocessProgram, 1, "in_TexCoord");
    glLinkProgram(_postprocessProgram);

    GLint linked;
    glGetProgramiv(_postprocessProgram, GL_LINK_STATUS, &linked);

    glDeleteShader(vShader);
    glDeleteShader(fShader);

    if (!linked) {
        NSLog(@"Error linking degamma program: %@", [self getProgramErrorLogForProgram:_postprocessProgram]);
        return NO;
    }
    _postprocessProgramTextureLocation = glGetUniformLocation(_postprocessProgram, "tex");

    glGenVertexArrays(1, &_postprocessProgramVAO);
    glBindVertexArray(_postprocessProgramVAO);
    glGenBuffers(1, &_postprocessProgramVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _postprocessProgramVBO);
    const float quadVertices[] =
    {
        // positions   // texCoords
        -1.0f,  1.0f,  0.0f, 0.0f,
        -1.0f, -1.0f,  0.0f, 1.0f,
         1.0f, -1.0f,  1.0f, 1.0f,

        -1.0f,  1.0f,  0.0f, 0.0f,
         1.0f, -1.0f,  1.0f, 1.0f,
         1.0f,  1.0f,  1.0f, 0.0f
    };
    glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertices), quadVertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), 0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(2 * sizeof(float)));
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    return YES;
}

- (void)cleanupEGL {
    if (_eglContext != EGL_NO_CONTEXT) {
        eglMakeCurrent(_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContext(_eglDisplay, _eglContext);
        _eglContext = EGL_NO_CONTEXT;
    }

    if (_eglDisplay != EGL_NO_DISPLAY) {
        eglTerminate(_eglDisplay);
        _eglDisplay = EGL_NO_DISPLAY;
    }
}

- (void)cleanupGL {
    if (_eglDisplay == EGL_NO_DISPLAY || _eglContext == EGL_NO_CONTEXT)
        return;

    eglMakeCurrent(_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, _eglContext);
    if (_postprocessProgramVAO != 0) {
        glDeleteVertexArrays(1, &_postprocessProgramVAO);
        _postprocessProgramVAO = 0;
    }
    if (_postprocessProgramVBO != 0) {
        glDeleteBuffers(1, &_postprocessProgramVBO);
        _postprocessProgramVBO = 0;
    }
    _postprocessProgramTextureLocation = 0;
    if (_postprocessProgram != 0) {
        glDeleteProgram(_postprocessProgram);
        _postprocessProgram = 0;
    }
}

@end
