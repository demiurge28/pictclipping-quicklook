#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <QuickLook/QuickLook.h>
#import <sys/xattr.h>

/// Preferred UTI keys in the data fork bplist, in priority order.
static NSArray<NSString *> *preferredUTIs(void) {
    return @[
        @"public.tiff",
        @"public.png",
        @"public.jpeg",
        @"com.apple.pict",
    ];
}

/// Try to extract an image from the data fork (binary plist).
static NSImage *imageFromDataFork(NSURL *url) {
    NSData *fileData = [NSData dataWithContentsOfURL:url];
    if (!fileData) return nil;

    NSDictionary *plist = [NSPropertyListSerialization
        propertyListWithData:fileData
        options:NSPropertyListImmutable
        format:NULL
        error:NULL];
    if (![plist isKindOfClass:[NSDictionary class]]) return nil;

    NSDictionary *utiData = plist[@"UTI-Data"];
    if (![utiData isKindOfClass:[NSDictionary class]]) return nil;

    // Try preferred formats first.
    for (NSString *uti in preferredUTIs()) {
        NSData *imgData = utiData[uti];
        if ([imgData isKindOfClass:[NSData class]] && imgData.length > 0) {
            NSImage *img = [[NSImage alloc] initWithData:imgData];
            if (img) return img;
        }
    }

    // Fall back to any key that yields a valid image.
    for (NSString *key in utiData) {
        NSData *imgData = utiData[key];
        if ([imgData isKindOfClass:[NSData class]] && imgData.length > 0) {
            NSImage *img = [[NSImage alloc] initWithData:imgData];
            if (img) return img;
        }
    }
    return nil;
}

/// Try to extract an image from the com.apple.ResourceFork xattr.
static NSImage *imageFromResourceFork(NSURL *url) {
    const char *path = url.fileSystemRepresentation;
    const char *name = "com.apple.ResourceFork";

    ssize_t size = getxattr(path, name, NULL, 0, 0, 0);
    if (size <= 0) return nil;

    NSMutableData *buf = [NSMutableData dataWithLength:(NSUInteger)size];
    ssize_t read = getxattr(path, name, buf.mutableBytes, (size_t)size, 0, 0);
    if (read != size) return nil;

    // Try raw data as image first.
    NSImage *img = [[NSImage alloc] initWithData:buf];
    if (img) return img;

    // Scan for TIFF magic bytes (II* or MM*).
    const uint8_t *bytes = buf.bytes;
    for (NSUInteger i = 0; i + 4 < buf.length; i++) {
        BOOL isLE = (bytes[i] == 0x49 && bytes[i+1] == 0x49
                     && bytes[i+2] == 0x2A && bytes[i+3] == 0x00);
        BOOL isBE = (bytes[i] == 0x4D && bytes[i+1] == 0x4D
                     && bytes[i+2] == 0x00 && bytes[i+3] == 0x2A);
        if (isLE || isBE) {
            NSData *tiff = [buf subdataWithRange:NSMakeRange(i, buf.length - i)];
            img = [[NSImage alloc] initWithData:tiff];
            if (img) return img;
        }
    }
    return nil;
}

static NSImage *imageFromPictClipping(NSURL *url) {
    NSImage *img = imageFromDataFork(url);
    if (img) return img;
    return imageFromResourceFork(url);
}

// ---------- QuickLook Callbacks ----------

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview,
                                CFURLRef url, CFStringRef contentTypeUTI,
                                CFDictionaryRef options) {
    @autoreleasepool {
        if (QLPreviewRequestIsCancelled(preview)) return noErr;

        NSImage *image = imageFromPictClipping((__bridge NSURL *)url);
        if (!image) return noErr;

        NSSize size = image.size;
        if (size.width <= 0 || size.height <= 0) return noErr;

        CGContextRef ctx = QLPreviewRequestCreateContext(preview,
            NSSizeToCGSize(size), true, NULL);
        if (!ctx) return noErr;

        NSGraphicsContext *nsCtx = [NSGraphicsContext
            graphicsContextWithCGContext:ctx flipped:NO];
        [NSGraphicsContext setCurrentContext:nsCtx];
        [image drawInRect:NSMakeRect(0, 0, size.width, size.height)];
        [NSGraphicsContext setCurrentContext:nil];

        QLPreviewRequestFlushContext(preview, ctx);
        CFRelease(ctx);
    }
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) {
    // nothing to cancel
}

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail,
                                  CFURLRef url, CFStringRef contentTypeUTI,
                                  CFDictionaryRef options, CGSize maxSize) {
    @autoreleasepool {
        if (QLThumbnailRequestIsCancelled(thumbnail)) return noErr;

        NSImage *image = imageFromPictClipping((__bridge NSURL *)url);
        if (!image) return noErr;

        NSSize size = image.size;
        if (size.width <= 0 || size.height <= 0) return noErr;

        // Scale to fit maxSize while preserving aspect ratio.
        CGFloat scale = fmin(maxSize.width / size.width, maxSize.height / size.height);
        if (scale > 1.0) scale = 1.0;
        CGSize thumbSize = CGSizeMake(size.width * scale, size.height * scale);

        CGContextRef ctx = QLThumbnailRequestCreateContext(thumbnail, thumbSize, true, NULL);
        if (!ctx) return noErr;

        NSGraphicsContext *nsCtx = [NSGraphicsContext
            graphicsContextWithCGContext:ctx flipped:NO];
        [NSGraphicsContext setCurrentContext:nsCtx];
        [image drawInRect:NSMakeRect(0, 0, thumbSize.width, thumbSize.height)];
        [NSGraphicsContext setCurrentContext:nil];

        QLThumbnailRequestFlushContext(thumbnail, ctx);
        CFRelease(ctx);
    }
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail) {
    // nothing to cancel
}
