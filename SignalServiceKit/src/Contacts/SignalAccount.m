//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

#import "SignalAccount.h"
#import "Contact.h"
#import "ContactsManagerProtocol.h"
#import "NSData+Image.h"
#import "SSKEnvironment.h"
#import "SignalRecipient.h"
#import "UIImage+OWS.h"
#import <SignalCoreKit/Cryptography.h>
#import <SignalCoreKit/NSString+OWS.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSUInteger const SignalAccountSchemaVersion = 1;

@interface SignalAccount ()

@property (nonatomic, readonly) NSUInteger accountSchemaVersion;

@property (nonatomic) NSString *multipleAccountLabelText;

@property (nonatomic, nullable) Contact *contact;

@end

#pragma mark -

@implementation SignalAccount

#pragma mark - Dependencies

- (id<ContactsManagerProtocol>)contactsManager
{
    return SSKEnvironment.shared.contactsManager;
}

- (SignalAccountReadCache *)signalAccountReadCache
{
    return SSKEnvironment.shared.modelReadCaches.signalAccountReadCache;
}

#pragma mark -

+ (BOOL)shouldBeIndexedForFTS
{
    return YES;
}

- (instancetype)initWithSignalRecipient:(SignalRecipient *)signalRecipient
                                contact:(nullable Contact *)contact
               multipleAccountLabelText:(nullable NSString *)multipleAccountLabelText
{
    OWSAssertDebug(signalRecipient);
    return [self initWithSignalServiceAddress:signalRecipient.address
                                      contact:contact
                     multipleAccountLabelText:multipleAccountLabelText];
}

- (instancetype)initWithSignalServiceAddress:(SignalServiceAddress *)serviceAddress
{
    return [self initWithSignalServiceAddress:serviceAddress contact:nil multipleAccountLabelText:nil];
}

- (instancetype)initWithSignalServiceAddress:(SignalServiceAddress *)serviceAddress
                                     contact:(nullable Contact *)contact
                    multipleAccountLabelText:(nullable NSString *)multipleAccountLabelText
{
    OWSAssertDebug(serviceAddress.isValid);
    if (self = [super init]) {
        _recipientUUID = serviceAddress.uuidString;
        _recipientPhoneNumber = serviceAddress.phoneNumber;
        _accountSchemaVersion = SignalAccountSchemaVersion;
        _contact = contact;
        _multipleAccountLabelText = multipleAccountLabelText;
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    // Migrating from an everyone has a phone number world to a
    // world in which we have UUIDs
    if (_accountSchemaVersion == 0) {
        // Rename recipientId to recipientPhoneNumber
        _recipientPhoneNumber = [coder decodeObjectForKey:@"recipientId"];

        OWSAssert(_recipientPhoneNumber != nil);
    }

    _accountSchemaVersion = SignalAccountSchemaVersion;

    return self;
}

- (instancetype)initWithContact:(nullable Contact *)contact
              contactAvatarHash:(nullable NSData *)contactAvatarHash
          contactAvatarJpegData:(nullable NSData *)contactAvatarJpegData
       multipleAccountLabelText:(NSString *)multipleAccountLabelText
           recipientPhoneNumber:(nullable NSString *)recipientPhoneNumber
                  recipientUUID:(nullable NSString *)recipientUUID
{
    self = [super init];
    if (!self) {
        return self;
    }

    OWSAssertDebug(recipientPhoneNumber != nil || recipientUUID != nil);
    OWSAssertDebug(recipientPhoneNumber != nil || RemoteConfig.allowUUIDOnlyContacts);

    _contact = contact;
    _contactAvatarHash = contactAvatarHash;
    _contactAvatarJpegData = contactAvatarJpegData;
    _multipleAccountLabelText = multipleAccountLabelText;
    _recipientPhoneNumber = recipientPhoneNumber;
    _recipientUUID = recipientUUID;
    _accountSchemaVersion = SignalAccountSchemaVersion;

    return self;
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
                         contact:(nullable Contact *)contact
               contactAvatarHash:(nullable NSData *)contactAvatarHash
           contactAvatarJpegData:(nullable NSData *)contactAvatarJpegData
        multipleAccountLabelText:(NSString *)multipleAccountLabelText
            recipientPhoneNumber:(nullable NSString *)recipientPhoneNumber
                   recipientUUID:(nullable NSString *)recipientUUID
{
    self = [super initWithGrdbId:grdbId
                        uniqueId:uniqueId];

    if (!self) {
        return self;
    }

    _contact = contact;
    _contactAvatarHash = contactAvatarHash;
    _contactAvatarJpegData = contactAvatarJpegData;
    _multipleAccountLabelText = multipleAccountLabelText;
    _recipientPhoneNumber = recipientPhoneNumber;
    _recipientUUID = recipientUUID;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

- (nullable NSString *)contactFullName
{
    return self.contact.fullName.filterStringForDisplay;
}

- (nullable NSString *)contactFirstName
{
    return self.contact.firstName.filterStringForDisplay;
}

- (nullable NSString *)contactLastName
{
    return self.contact.lastName.filterStringForDisplay;
}

- (NSString *)multipleAccountLabelText
{
    NSString *_Nullable result = _multipleAccountLabelText.filterStringForDisplay;
    return result != nil ? result : @"";
}

- (SignalServiceAddress *)recipientAddress
{
    return [[SignalServiceAddress alloc] initWithUuidString:self.recipientUUID phoneNumber:self.recipientPhoneNumber];
}

- (BOOL)hasSameContent:(SignalAccount *)other
{
    OWSAssertDebug(other != nil);

    // NOTE: We don't want to compare contactAvatarJpegData.
    //       It can't change without contactAvatarHash changing
    //       as well.
    return ([NSObject isNullableObject:self.recipientPhoneNumber equalTo:other.recipientPhoneNumber] &&
        [NSObject isNullableObject:self.recipientUUID equalTo:other.recipientUUID] &&
        [NSObject isNullableObject:self.contact equalTo:other.contact] &&
        [NSObject isNullableObject:self.multipleAccountLabelText equalTo:other.multipleAccountLabelText] &&
        [NSObject isNullableObject:self.contactAvatarHash equalTo:other.contactAvatarHash]);
}

- (void)tryToCacheContactAvatarData
{
    OWSAssertDebug(self.contactAvatarHash == nil);
    OWSAssertDebug(self.contactAvatarJpegData == nil);

    if (self.contact == nil) {
        OWSFailDebug(@"Missing contact.");
        return;
    }

    if (self.contact.isFromContactSync) {
        OWSLogVerbose(@"not caching data for synced contact");
        return;
    }

    OWSAssertDebug(self.contact.cnContactId);
    NSData *_Nullable contactAvatarData = [self.contactsManager avatarDataForCNContactId:self.contact.cnContactId];
    if (contactAvatarData == nil) {
        return;
    }
    _contactAvatarHash = [Cryptography computeSHA256Digest:contactAvatarData];
    OWSAssertDebug(self.contactAvatarHash != nil);
    if (self.contactAvatarHash == nil) {
        return;
    }

    _contactAvatarJpegData = [UIImage validJpegDataFromAvatarData:contactAvatarData];
    if (self.contactAvatarJpegData == nil) {
        OWSFailDebug(@"Could not convert avatar to JPEG.");
        return;
    }
}

- (void)anyDidInsertWithTransaction:(SDSAnyWriteTransaction *)transaction
{
    [super anyDidInsertWithTransaction:transaction];

    [self.signalAccountReadCache didInsertOrUpdateSignalAccount:self transaction:transaction];
}

- (void)anyDidUpdateWithTransaction:(SDSAnyWriteTransaction *)transaction
{
    [super anyDidUpdateWithTransaction:transaction];

    [self.signalAccountReadCache didInsertOrUpdateSignalAccount:self transaction:transaction];
}

- (void)anyDidRemoveWithTransaction:(SDSAnyWriteTransaction *)transaction
{
    [super anyDidRemoveWithTransaction:transaction];

    [self.signalAccountReadCache didRemoveSignalAccount:self transaction:transaction];
}

- (void)updateWithContact:(nullable Contact *)contact transaction:(SDSAnyWriteTransaction *)transaction
{
    [self anyUpdateWithTransaction:transaction
                             block:^(SignalAccount *account) {
                                 account.contact = contact;
                             }];
}

#if TESTABLE_BUILD
- (void)replaceContactForTests:(nullable Contact *)contact
{
    self.contact = contact;
}
#endif

@end

NS_ASSUME_NONNULL_END
