//
//  NRBitStampTicker.m
//  CoinUp
//
//  Created by Zhefu Wang on 13-10-25.
//  Copyright (c) 2013年 Nonomori. All rights reserved.
//

#import "NRBITSTAMPTicker.h"
#import "JSONKit.h"

#define URL @"https://www.bitstamp.net/api/ticker/"
#define PLATFORMNAME @"BITSTAMP"

@implementation NRBitStampTicker

- (NRBitStampTicker*)init
{
    [self addObserver:self
           forKeyPath:@"last"
              options:(NSKeyValueObservingOptionOld)
              context:NULL];
    [self addObserver:self
           forKeyPath:@"high"
              options:(NSKeyValueObservingOptionOld)
              context:NULL];
    [self addObserver:self
           forKeyPath:@"low"
              options:(NSKeyValueObservingOptionOld)
              context:NULL];
    [self addObserver:self
           forKeyPath:@"vol"
              options:(NSKeyValueObservingOptionOld)
              context:NULL];
    [self addObserver:self
           forKeyPath:@"ask"
              options:(NSKeyValueObservingOptionOld)
              context:NULL];
    [self addObserver:self
           forKeyPath:@"bid"
              options:(NSKeyValueObservingOptionOld)
              context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateInfoWindow) name:@"InfoWindowUpdate" object:nil];

    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)update:(id)userInfo
{
    __block NSData *jsonData;
    __weak NRBitStampTicker* weakSelf = self;
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Queue", NULL);
	dispatch_async(downloadQueue, ^{
        jsonData = [NSData dataWithContentsOfURL:[NSURL URLWithString:URL]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (jsonData)
            {
                NSDictionary *jsonObject = [[[JSONDecoder alloc] init] objectWithData:jsonData];
                weakSelf.last = [jsonObject[@"last"] doubleValue];
                weakSelf.high = [jsonObject[@"high"] doubleValue];
                weakSelf.low = [jsonObject[@"low"] doubleValue];
                weakSelf.vol = [jsonObject[@"volume"] doubleValue];
                weakSelf.ask = [jsonObject[@"ask"] doubleValue];
                weakSelf.bid = [jsonObject[@"bid"] doubleValue];
            }
            else
            {
                weakSelf.last = UNAVAILABLE;
                weakSelf.high = UNAVAILABLE;
                weakSelf.low = UNAVAILABLE;
                weakSelf.vol = UNAVAILABLE;
                weakSelf.ask = UNAVAILABLE;
                weakSelf.bid = UNAVAILABLE;
            }
        });
	});
	dispatch_release(downloadQueue);
}

- (void)start
{
    [self update:nil];
    [NSTimer scheduledTimerWithTimeInterval:5
                                     target:self
                                   selector:@selector(update:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"last"])
    {
        if (self.last != UNAVAILABLE)
            [self.delegate updateLabel:[NSString stringWithFormat:@"$%.2f",self.last] ForName:PLATFORMNAME];
        else
            [self.delegate updateLabel:@"N/A" ForName:PLATFORMNAME];
        
        if ([change[@"old"] doubleValue] > self.last)
            [self.delegate flashColorInGreen:NO ForName:PLATFORMNAME];
        else if ([change[@"old"] doubleValue] < self.last)
            [self.delegate flashColorInGreen:YES ForName:PLATFORMNAME];
        else{}
    }
    else
    {
//        if ([[self valueForKey:keyPath] doubleValue] != UNAVAILABLE)
//        {
            [self updateInfoWindow];
//        }
//        else
//            [self.delegate setInfoWindowForHigh:@"N/A" Low:@"N/A" Ask:@"N/A" Bid:@"N/A" Vol:@"N/A"];
    }
}

- (void)updateInfoWindow
{
    if ([self.delegate currentPlatformType] == BITSTAMP)
    {
        if (self.low == UNAVAILABLE || self.high == UNAVAILABLE || self.ask == UNAVAILABLE || self.bid == UNAVAILABLE || self.vol == UNAVAILABLE)
        {
            [self.delegate setInfoWindowForHigh:@"N/A" Low:@"N/A" Ask:@"N/A" Bid:@"N/A" Vol:@"N/A"];
        }
        else
        {
            [self.delegate setInfoWindowForHigh:[NSString stringWithFormat:@"$%.2f",self.high] Low:[NSString stringWithFormat:@"$%.2f",self.low] Ask:[NSString stringWithFormat:@"$%.2f",self.ask] Bid:[NSString stringWithFormat:@"$%.2f",self.bid] Vol:[NSString stringWithFormat:@"฿%.2f",self.vol]];
        }
    }
}

@end
