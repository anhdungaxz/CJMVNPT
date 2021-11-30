/*
 *  NSData+CommonCrypto.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
 *
 *  Copyright (c) 2008-2009, Jim Dovey
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *  
 *  Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *  
 *  Neither the name of this project's author nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import <Foundation/Foundation.h>
#import "CJMNSData+CommonCrypto.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>

NSString * const kCommonCryptoErrorDomain_CJM = @"CommonCryptoErrorDomain_CJM";

@implementation NSError (CommonCryptoErrorDomain)

+ (NSError *) cjm_errorWithCCCryptorStatus: (CCCryptorStatus) status
{
	NSString * description = nil, * reason = nil;
	
	switch ( status )
	{
		case kCCSuccess:
			description = NSLocalizedString(@"Success", @"Error description");
			break;
			
		case kCCParamError:
			description = NSLocalizedString(@"Parameter Error", @"Error description");
			reason = NSLocalizedString(@"Illegal parameter supplied to encryption/decryption algorithm", @"Error reason");
			break;
			
		case kCCBufferTooSmall:
			description = NSLocalizedString(@"Buffer Too Small", @"Error description");
			reason = NSLocalizedString(@"Insufficient buffer provided for specified operation", @"Error reason");
			break;
			
		case kCCMemoryFailure:
			description = NSLocalizedString(@"Memory Failure", @"Error description");
			reason = NSLocalizedString(@"Failed to allocate memory", @"Error reason");
			break;
			
		case kCCAlignmentError:
			description = NSLocalizedString(@"Alignment Error", @"Error description");
			reason = NSLocalizedString(@"Input size to encryption algorithm was not aligned correctly", @"Error reason");
			break;
			
		case kCCDecodeError:
			description = NSLocalizedString(@"Decode Error", @"Error description");
			reason = NSLocalizedString(@"Input data did not decode or decrypt correctly", @"Error reason");
			break;
			
		case kCCUnimplemented:
			description = NSLocalizedString(@"Unimplemented Function", @"Error description");
			reason = NSLocalizedString(@"Function not implemented for the current algorithm", @"Error reason");
			break;
			
		default:
			description = NSLocalizedString(@"Unknown Error", @"Error description");
			break;
	}
	
	NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject: description forKey: NSLocalizedDescriptionKey];
	
	if ( reason != nil )
		[userInfo setObject: reason forKey: NSLocalizedFailureReasonErrorKey];
	
	NSError * result = [NSError errorWithDomain: kCommonCryptoErrorDomain_CJM code: status userInfo: userInfo];
    #if !__has_feature(objc_arc)
        [userInfo release];
    #endif
	
	return ( result );
}

@end

#pragma mark -

@implementation NSData (CommonDigest)

- (NSData *) cjm_MD2Sum
{
	unsigned char hash[CC_MD2_DIGEST_LENGTH];
	(void) CC_MD2( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD2_DIGEST_LENGTH] );
}

- (NSData *) cjm_MD4Sum
{
	unsigned char hash[CC_MD4_DIGEST_LENGTH];
	(void) CC_MD4( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD4_DIGEST_LENGTH] );
}

- (NSData *) cjm_MD5Sum
{
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	(void) CC_MD5( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD5_DIGEST_LENGTH] );
}

- (NSData *) cjm_SHA1Hash
{
	unsigned char hash[CC_SHA1_DIGEST_LENGTH];
	(void) CC_SHA1( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA1_DIGEST_LENGTH] );
}

- (NSData *) cjm_SHA224Hash
{
	unsigned char hash[CC_SHA224_DIGEST_LENGTH];
	(void) CC_SHA224( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA224_DIGEST_LENGTH] );
}

- (NSData *) cjm_SHA256Hash
{
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];
	(void) CC_SHA256( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA256_DIGEST_LENGTH] );
}

- (NSData *) cjm_SHA384Hash
{
	unsigned char hash[CC_SHA384_DIGEST_LENGTH];
	(void) CC_SHA384( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA384_DIGEST_LENGTH] );
}

- (NSData *) cjm_SHA512Hash
{
	unsigned char hash[CC_SHA512_DIGEST_LENGTH];
	(void) CC_SHA512( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA512_DIGEST_LENGTH] );
}

@end

@implementation NSData (CommonCryptor)

- (NSData *) cjm_AES256EncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self cjm_dataEncryptedUsingAlgorithm: kCCAlgorithmAES128
                                                  key: key
                                              options: kCCOptionPKCS7Padding
                                                error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError cjm_errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) cjm_decryptedAES256DataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self cjm_decryptedDataUsingAlgorithm: kCCAlgorithmAES128
                                                  key: key
                                              options: kCCOptionPKCS7Padding
                                                error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError cjm_errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) cjm_DESEncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self cjm_dataEncryptedUsingAlgorithm: kCCAlgorithmDES
                                                  key: key
                                              options: kCCOptionPKCS7Padding
                                                error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError cjm_errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) cjm_decryptedDESDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self cjm_decryptedDataUsingAlgorithm: kCCAlgorithmDES
                                                  key: key
                                              options: kCCOptionPKCS7Padding
                                                error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError cjm_errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) cjm_CASTEncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self cjm_dataEncryptedUsingAlgorithm: kCCAlgorithmCAST
                                                  key: key
                                              options: kCCOptionPKCS7Padding
                                                error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError cjm_errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) cjm_decryptedCASTDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self cjm_decryptedDataUsingAlgorithm: kCCAlgorithmCAST
                                                  key: key
                                              options: kCCOptionPKCS7Padding
                                                error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError cjm_errorWithCCCryptorStatus: status];
	
	return ( nil );
}

@end

static void FixKeyLengths( CCAlgorithm algorithm, NSMutableData * keyData, NSMutableData * ivData )
{
	NSUInteger keyLength = [keyData length];
	switch ( algorithm )
	{
		case kCCAlgorithmAES128:
		{
			if ( keyLength < 16 )
			{
				[keyData setLength: 16];
			}
			else if ( keyLength < 24 )
			{
				[keyData setLength: 24];
			}
			else
			{
				[keyData setLength: 32];
			}
			
			break;
		}
			
		case kCCAlgorithmDES:
		{
			[keyData setLength: 8];
			break;
		}
			
		case kCCAlgorithm3DES:
		{
			[keyData setLength: 24];
			break;
		}
			
		case kCCAlgorithmCAST:
		{
			if ( keyLength < 5 )
			{
				[keyData setLength: 5];
			}
			else if ( keyLength > 16 )
			{
				[keyData setLength: 16];
			}
			
			break;
		}
			
		case kCCAlgorithmRC4:
		{
			if ( keyLength > 512 )
				[keyData setLength: 512];
			break;
		}
			
		default:
			break;
	}
	
	[ivData setLength: [keyData length]];
}

@implementation NSData (LowLevelCommonCryptor)

- (NSData *) _runCryptor: (CCCryptorRef) cryptor result: (CCCryptorStatus *) status
{
	size_t bufsize = CCCryptorGetOutputLength( cryptor, (size_t)[self length], true );
	void * buf = malloc( bufsize );
	size_t bufused = 0;
  size_t bytesTotal = 0;
	*status = CCCryptorUpdate( cryptor, [self bytes], (size_t)[self length], 
                            buf, bufsize, &bufused );
	if ( *status != kCCSuccess )
	{
		free( buf );
		return ( nil );
	}
  
  bytesTotal += bufused;
	
	// From Brent Royal-Gordon (Twitter: architechies):
	//  Need to update buf ptr past used bytes when calling CCCryptorFinal()
	*status = CCCryptorFinal( cryptor, buf + bufused, bufsize - bufused, &bufused );
	if ( *status != kCCSuccess )
	{
		free( buf );
		return ( nil );
	}
  
  bytesTotal += bufused;
	
	return ( [NSData dataWithBytesNoCopy: buf length: bytesTotal] );
}

- (NSData *) cjm_dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
                                     key: (id) key
                                   error: (CCCryptorStatus *) error
{
	return ( [self cjm_dataEncryptedUsingAlgorithm: algorithm
                                         key: key
                        initializationVector: nil
                                     options: 0
                                       error: error] );
}

- (NSData *) cjm_dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
                                     key: (id) key
                                 options: (CCOptions) options
                                   error: (CCCryptorStatus *) error
{
  return ( [self cjm_dataEncryptedUsingAlgorithm: algorithm
                                         key: key
                        initializationVector: nil
                                     options: options
                                       error: error] );
}

- (NSData *) cjm_dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
                                     key: (id) key
                    initializationVector: (id) iv
                                 options: (CCOptions) options
                                   error: (CCCryptorStatus *) error
{
	CCCryptorRef cryptor = NULL;
	CCCryptorStatus status = kCCSuccess;
	
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert(iv == nil || [iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
	
	NSMutableData * keyData, * ivData;
	if ( [key isKindOfClass: [NSData class]] )
		keyData = (NSMutableData *) [key mutableCopy];
	else
		keyData = [[key dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	
	if ( [iv isKindOfClass: [NSString class]] )
		ivData = [[iv dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	else
		ivData = (NSMutableData *) [iv mutableCopy];	// data or nil
	
    #if !__has_feature(objc_arc)
        [keyData autorelease];
        [ivData autorelease];
	#endif
	// ensure correct lengths for key and iv data, based on algorithms
	FixKeyLengths( algorithm, keyData, ivData );
	
	status = CCCryptorCreate( kCCEncrypt, algorithm, options,
                           [keyData bytes], [keyData length], [ivData bytes],
                           &cryptor );
	
	if ( status != kCCSuccess )
	{
		if ( error != NULL )
			*error = status;
		return ( nil );
	}
	
	NSData * result = [self _runCryptor: cryptor result: &status];
	if ( (result == nil) && (error != NULL) )
		*error = status;
	
	CCCryptorRelease( cryptor );
	
	return ( result );
}

- (NSData *) cjm_decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
                                     key: (id) key		// data or string
                                   error: (CCCryptorStatus *) error
{
	return ( [self cjm_decryptedDataUsingAlgorithm: algorithm
                                         key: key
                        initializationVector: nil
                                     options: 0
                                       error: error] );
}

- (NSData *) cjm_decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
                                     key: (id) key		// data or string
                                 options: (CCOptions) options
                                   error: (CCCryptorStatus *) error
{
  return ( [self cjm_decryptedDataUsingAlgorithm: algorithm
                                         key: key
                        initializationVector: nil
                                     options: options
                                       error: error] );
}

- (NSData *) cjm_decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
                                     key: (id) key		// data or string
                    initializationVector: (id) iv		// data or string
                                 options: (CCOptions) options
                                   error: (CCCryptorStatus *) error
{
	CCCryptorRef cryptor = NULL;
	CCCryptorStatus status = kCCSuccess;
	
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert(iv == nil || [iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
	
	NSMutableData * keyData, * ivData;
	if ( [key isKindOfClass: [NSData class]] )
		keyData = (NSMutableData *) [key mutableCopy];
	else
		keyData = [[key dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	
	if ( [iv isKindOfClass: [NSString class]] )
		ivData = [[iv dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	else
		ivData = (NSMutableData *) [iv mutableCopy];	// data or nil
	
    #if !__has_feature(objc_arc)
        [keyData autorelease];
        [ivData autorelease];
    #endif
	
	// ensure correct lengths for key and iv data, based on algorithms
	FixKeyLengths( algorithm, keyData, ivData );
	
	status = CCCryptorCreate( kCCDecrypt, algorithm, options,
                           [keyData bytes], [keyData length], [ivData bytes],
                           &cryptor );
	
	if ( status != kCCSuccess )
	{
		if ( error != NULL )
			*error = status;
		return ( nil );
	}
	
	NSData * result = [self _runCryptor: cryptor result: &status];
	if ( (result == nil) && (error != NULL) )
		*error = status;
	
	CCCryptorRelease( cryptor );
	
	return ( result );
}

@end

@implementation NSData (CommonHMAC)

- (NSData *) cjm_HMACWithAlgorithm: (CCHmacAlgorithm) algorithm
{
	return ( [self cjm_HMACWithAlgorithm: algorithm key: nil] );
}

- (NSData *) cjm_HMACWithAlgorithm: (CCHmacAlgorithm) algorithm key: (id) key
{
	NSParameterAssert(key == nil || [key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	
	NSData * keyData = nil;
	if ( [key isKindOfClass: [NSString class]] )
		keyData = [key dataUsingEncoding: NSUTF8StringEncoding];
	else
		keyData = (NSData *) key;
	
	// this could be either CC_SHA1_DIGEST_LENGTH or CC_MD5_DIGEST_LENGTH. SHA1 is larger.
	unsigned char buf[CC_SHA1_DIGEST_LENGTH];
	CCHmac( algorithm, [keyData bytes], [keyData length], [self bytes], [self length], buf );
	
	return ( [NSData dataWithBytes: buf length: (algorithm == kCCHmacAlgMD5 ? CC_MD5_DIGEST_LENGTH : CC_SHA1_DIGEST_LENGTH)] );
}

@end
