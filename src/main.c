#include <CoreFoundation/CoreFoundation.h>
#include <CoreFoundation/CFPlugInCOM.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview,
                                CFURLRef url, CFStringRef contentTypeUTI,
                                CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail,
                                  CFURLRef url, CFStringRef contentTypeUTI,
                                  CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

// ---------- QuickLook Generator Plugin Boilerplate ----------
// QLGeneratorInterfaceStruct is defined in <QuickLook/QLGenerator.h>

static ULONG _refCount = 0;

static HRESULT _QueryInterface(void *thisInterface, REFIID iid, LPVOID *ppv) {
    CFUUIDRef requested = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, iid);
    CFUUIDRef qlGen = CFUUIDCreateFromString(kCFAllocatorDefault,
        CFSTR("865AF5E0-6D30-4345-951B-D37105754F2D"));

    if (CFEqual(requested, qlGen)) {
        ((QLGeneratorInterfaceStruct *)thisInterface)->AddRef(thisInterface);
        *ppv = thisInterface;
        CFRelease(requested);
        CFRelease(qlGen);
        return S_OK;
    }
    CFRelease(requested);
    CFRelease(qlGen);
    *ppv = NULL;
    return E_NOINTERFACE;
}

static ULONG _AddRef(void *thisInterface) {
    return ++_refCount;
}

static ULONG _Release(void *thisInterface) {
    if (--_refCount == 0) {
        free(thisInterface);
        return 0;
    }
    return _refCount;
}

static QLGeneratorInterfaceStruct gInterface = {
    NULL,
    _QueryInterface,
    _AddRef,
    _Release,
    GenerateThumbnailForURL,
    CancelThumbnailGeneration,
    GeneratePreviewForURL,
    CancelPreviewGeneration,
};

void *QuickLookGeneratorPluginFactory(CFAllocatorRef allocator, CFUUIDRef typeID) {
    CFUUIDRef qlGenType = CFUUIDCreateFromString(kCFAllocatorDefault,
        CFSTR("5E2D9680-5022-40FA-B806-43349622E5B9"));

    if (CFEqual(typeID, qlGenType)) {
        CFRelease(qlGenType);
        _refCount++;
        return &gInterface;
    }
    CFRelease(qlGenType);
    return NULL;
}
