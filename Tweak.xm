#import <UIKit/UIKit.h>
#import <AdSupport/ASIdentifierManager.h>
#import <Security/Security.h>
#import <sys/utsname.h>

NSString *RandomUUID() {
    return [[NSUUID UUID] UUIDString];
}

// Store new randoms per launch
static NSString *randIDFV = nil;
static NSString *randAdID = nil;
static NSMutableDictionary *randKeychain = nil;

%hook UIDevice
- (NSUUID *)identifierForVendor {
    if (!randIDFV) {
        randIDFV = RandomUUID();
    }
    return [[NSUUID alloc] initWithUUIDString:randIDFV];
}
- (NSString *)systemVersion {
    return @"17.1"; // Fake version (optional)
}
- (NSString *)model {
    return @"iPhone14,3"; // Fake model (optional)
}
%end

%hook ASIdentifierManager
- (NSUUID *)advertisingIdentifier {
    if (!randAdID) {
        randAdID = RandomUUID();
    }
    return [[NSUUID alloc] initWithUUIDString:randAdID];
}
%end

// --- Keychain spoof ---
NSDictionary *dictionaryFromCFDict(CFDictionaryRef dict) {
    return (__bridge NSDictionary *)dict;
}

CFTypeRef fakeResultForQuery(CFDictionaryRef query) {
    NSString *key = dictionaryFromCFDict(query)[(__bridge id)kSecAttrAccount];
    if (!key) key = @"default_key";
    
    if (!randKeychain) {
        randKeychain = [NSMutableDictionary dictionary];
    }
    
    // Always give a fresh random value for this launch
    randKeychain[key] = RandomUUID();
    
    return (__bridge_retained CFTypeRef)randKeychain[key];
}

OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef *);
OSStatus my_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    if (result) {
        *result = fakeResultForQuery(query);
        return errSecSuccess;
    }
    return orig_SecItemCopyMatching(query, result);
}

%ctor {
    MSHookFunction((void *)SecItemCopyMatching, (void *)my_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching);

    // Reset on every launch
    randIDFV = nil;
    randAdID = nil;
    randKeychain = nil;
}
