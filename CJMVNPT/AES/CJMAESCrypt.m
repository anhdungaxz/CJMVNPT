//
//  CJMAESCrypt.m
//  Gurpartap Singh
//
//  Created by Gurpartap Singh on 06/05/12.
//  Copyright (c) 2012 Gurpartap Singh
// 
// 	MIT License
// 
// 	Permission is hereby granted, free of charge, to any person obtaining
// 	a copy of this software and associated documentation files (the
// 	"Software"), to deal in the Software without restriction, including
// 	without limitation the rights to use, copy, modify, merge, publish,
// 	distribute, sublicense, and/or sell copies of the Software, and to
// 	permit persons to whom the Software is furnished to do so, subject to
// 	the following conditions:
// 
// 	The above copyright notice and this permission notice shall be
// 	included in all copies or substantial portions of the Software.
// 
// 	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// 	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// 	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// 	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// 	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// 	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// 	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "CJMAESCrypt.h"

#import "CJMNSData+Base64.h"
#import "CJMNSString+Base64.h"
#import "CJMNSData+CommonCrypto.h"

@implementation CJMAESCrypt

+ (NSString *)cjm_encrypt:(NSString *)message password:(NSString *)password {
  NSData *encryptedData = [[message dataUsingEncoding:NSUTF8StringEncoding] cjm_AES256EncryptedDataUsingKey:[password dataUsingEncoding:NSUTF8StringEncoding] error:nil];
  NSString *base64EncodedString = [NSString cjm_base64StringFromData:encryptedData length:[encryptedData length]];
  return base64EncodedString;
}

+ (NSString *)cjm_decrypt:(NSString *)base64EncodedString password:(NSString *)password {
  NSData *encryptedData = [NSData cjm_base64DataFromString:base64EncodedString];
  NSData *decryptedData = [encryptedData cjm_decryptedAES256DataUsingKey:[password dataUsingEncoding:NSUTF8StringEncoding]error:nil];
  return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
}

@end
