//
//  HSKDTreeInnerNode.m
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

#import "HSKDTreeInnerNode.h"

@interface HSKDTreeInnerNode ()

@property (nonatomic) NSUInteger leafsCount;
@property (nonatomic) HSKDTreeLine line;

@property (nonatomic, strong) HSKDTreeNode *leftNode;
@property (nonatomic, strong) HSKDTreeNode *rightNode;

@end

@implementation HSKDTreeInnerNode

#pragma mark - NSObject methods

- (NSString *)description {
	return [NSString stringWithFormat:@"Node (%p) { depth: %i, leafsCount: %i, %@ }",
			self, self.depth, self.leafsCount, NSStringFromHSKDTreeLine(self.line)];
}

#pragma mark - HSKDTreeNode methods

- (NSString *)recursiveDescription {
	NSString *padding = [@"" stringByPaddingToLength:self.depth + 1 withString:@" " startingAtIndex:0];
	
	return [[self description] stringByAppendingFormat:@"\n%@ Left %@\n%@ Right %@",
			padding, [self.leftNode recursiveDescription], padding, [self.rightNode recursiveDescription]];
}

@end
