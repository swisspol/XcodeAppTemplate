//  Copyright (C) 2014 Pierre-Olivier Latour <info@pol-online.net>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Crashlytics/Crashlytics.h>

#import "AppDelegate.h"
#import "MixpanelTracker.h"

#define kUserDefaultKey_ChecksumFiles @"checksumFiles"
#define kUserDefaultKey_ProductPrice @"productPrice"

#define kInAppProductIdentifier @"template_product"

@implementation AppDelegate

+ (void)initialize {
  NSDictionary* defaults = @{
                             // TODO
                             };
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)awakeFromNib {
  ; // TODO
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
#ifdef NDEBUG
//  [Crashlytics startWithAPIKey:@""];  // TODO
#endif
  
  [[InAppStore sharedStore] setDelegate:self];
  
#ifdef NDEBUG
//  [MixpanelTracker startWithToken:@""];  // TODO
#else
//  [MixpanelTracker startWithToken:@""];  // TODO
#endif
  
  [_mainWindow makeKeyAndOrderFront:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender {
  if ([[InAppStore sharedStore] isPurchasing] || [[InAppStore sharedStore] isRestoring]) {
    return NSTerminateCancel;
  }
  return NSTerminateNow;
}

- (BOOL)windowShouldClose:(id)sender {
  [NSApp terminate:nil];
  return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem {
  if ((menuItem.action == @selector(purchaseFeature:)) || (menuItem.action == @selector(restorePurchases:))) {
    return ![[InAppStore sharedStore] hasPurchasedProductWithIdentifier:kInAppProductIdentifier] && ![[InAppStore sharedStore] isPurchasing] && ![[InAppStore sharedStore] isRestoring];
  }
  return YES;
}

- (void)inAppStore:(InAppStore*)store didFindProductWithIdentifier:(NSString*)identifier price:(NSDecimalNumber*)price currencyLocale:(NSLocale*)locale {
  [[NSUserDefaults standardUserDefaults] setObject:price forKey:kUserDefaultKey_ProductPrice];
}

- (void)inAppStore:(InAppStore*)store didPurchaseProductWithIdentifier:(NSString*)identifier {
  MIXPANEL_TRACK_EVENT(@"Finish Purchase", nil);
  MIXPANEL_TRACK_PURCHASE([[NSUserDefaults standardUserDefaults] floatForKey:kUserDefaultKey_ProductPrice], nil);
  if ([[InAppStore sharedStore] isPurchasing]) {
    NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ALERT_PURCHASE_TITLE", nil)
                                     defaultButton:NSLocalizedString(@"ALERT_PURCHASE_DEFAULT_BUTTON", nil)
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"ALERT_PURCHASE_MESSAGE", nil)];
    [alert beginSheetModalForWindow:_mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
  }
}

- (void)inAppStoreDidCancelPurchase:(InAppStore*)store {
  MIXPANEL_TRACK_EVENT(@"Cancel Purchase", nil);
}

- (void)inAppStore:(InAppStore*)store didRestoreProductWithIdentifier:(NSString*)identifier {
  MIXPANEL_TRACK_EVENT(@"Finish Restore", nil);
  if ([identifier isEqualToString:kInAppProductIdentifier]) {
    if ([[InAppStore sharedStore] isRestoring]) {
      [NSApp activateIgnoringOtherApps:YES];
      NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ALERT_RESTORE_TITLE", nil)
                                       defaultButton:NSLocalizedString(@"ALERT_RESTORE_DEFAULT_BUTTON", nil)
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"ALERT_RESTORE_MESSAGE", nil)];
      [alert beginSheetModalForWindow:_mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
  }
}

- (void)inAppStoreDidCancelRestore:(InAppStore*)store {
  MIXPANEL_TRACK_EVENT(@"Cancel Restore", nil);
}

- (void)_reportIAPError:(NSError*)error {
  MIXPANEL_TRACK_EVENT(@"IAP Error", @{@"Description": error.localizedDescription});
  [NSApp activateIgnoringOtherApps:YES];
  NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ALERT_IAP_FAILED_TITLE", nil)
                                   defaultButton:NSLocalizedString(@"ALERT_IAP_FAILED_BUTTON", nil)
                                 alternateButton:nil
                                     otherButton:nil
                       informativeTextWithFormat:NSLocalizedString(@"ALERT_IAP_FAILED_MESSAGE", nil), error.localizedDescription];
  [alert beginSheetModalForWindow:_mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (void)inAppStore:(InAppStore*)store didFailFindingProductWithIdentifier:(NSString*)identifier {
  [self _reportIAPError:nil];
}

- (void)inAppStore:(InAppStore*)store didFailPurchasingProductWithIdentifier:(NSString*)identifier error:(NSError*)error {
  [self _reportIAPError:error];
}

- (void)inAppStore:(InAppStore*)store didFailRestoreWithError:(NSError*)error {
  [self _reportIAPError:error];
}

- (IBAction)purchaseFeature:(id)sender {
  if ([[InAppStore sharedStore] purchaseProductWithIdentifier:kInAppProductIdentifier]) {
    MIXPANEL_TRACK_EVENT(@"Start Purchase", nil);
  } else {
    NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ALERT_UNAVAILABLE_TITLE", nil)
                                     defaultButton:NSLocalizedString(@"ALERT_UNAVAILABLE_DEFAULT_BUTTON", nil)
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"ALERT_UNAVAILABLE_MESSAGE", nil)];
    [alert beginSheetModalForWindow:_mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
  }
}

- (IBAction)restorePurchases:(id)sender {
  MIXPANEL_TRACK_EVENT(@"Restore Purchase", nil);
  [[InAppStore sharedStore] restorePurchases];
}

- (void)_purchaseAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
  MIXPANEL_TRACK_EVENT(@"Learn Purchase", @{@"Choice": [NSNumber numberWithInteger:returnCode]});
  if (returnCode == NSAlertDefaultReturn) {
    [self purchaseFeature:nil];
  }
}

@end
