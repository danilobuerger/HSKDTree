//
//  HSKDTreeLeafNode.m
//
//  Created by Danilo Bürger <danilo.buerger@hmspl.de>.
//  Copyright (c) 2013 Heimspiel GmbH <http://www.hmspl.de/>.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "HSKDTreeLeafNode.h"

@interface HSKDTreeLeafNode ()

@property (nonatomic) HSKDTreePoint point;

@end

@implementation HSKDTreeLeafNode

#pragma mark - Initialization methods

- (id)init {
	NSAssert(NO, @"Please call the designated initializer.");
	
	return nil;
}

- (id)initWithPoint:(HSKDTreePoint)point {
	self = [super init];
	
	if (self) {
		self.point = point;
	}
	
	return self;
}

+ (instancetype)leafNodeWithPoint:(HSKDTreePoint)point {
	return [[self alloc] initWithPoint:point];
}

#pragma mark - NSObject methods

- (NSString *)description {
	return [NSString stringWithFormat:@"Leaf (%p) { depth: %lu, %@ }", self,
			(unsigned long) self.depth, NSStringFromHSKDTreePoint(self.point)];
}

#pragma mark - Custom methods

- (double)distanceToPoint:(HSKDTreePoint)point {
	return sqrt([self squaredDistanceToPoint:point]);
}

- (double)squaredDistanceToPoint:(HSKDTreePoint)point {
    double squaredDistance = 0.0;
    
	NSUInteger dimensions = self.point.dimensions;
    for (NSUInteger d = 0; d < dimensions; d++) {
        squaredDistance += pow(HSKDTreePointComponent(self.point, d) - HSKDTreePointComponent(point, d), 2.0);
    }
    
    return squaredDistance;
}

@end
