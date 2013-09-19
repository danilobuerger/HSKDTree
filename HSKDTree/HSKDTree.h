//
//  HSKDTree.h
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

#import <Foundation/Foundation.h>

#import "HSKDTreeDefines.h"
#import "HSKDTreeNode.h"
#import "HSKDTreeInnerNode.h"
#import "HSKDTreeLeafNode.h"

@interface HSKDTree : NSObject

@property (nonatomic, readonly) NSUInteger dimensions;
@property (nonatomic, readonly) Class innerNodeClass;

@property (nonatomic, strong, readonly) HSKDTreeNode *rootNode;

- (id)initWithDimensions:(NSUInteger)dimensions innerNodeClass:(Class)innerNodeClass;
+ (instancetype)treeWithDimensions:(NSUInteger)dimensions;
+ (instancetype)treeWithDimensions:(NSUInteger)dimensions innerNodeClass:(Class)innerNodeClass;

- (void)constructTreeWithLeafNodes:(NSArray *)leafNodes completion:(void (^)(HSKDTreeNode *rootNode))block;
- (void)findNearestNeighborToPoint:(HSKDTreePoint)point completion:(void (^)(HSKDTreeLeafNode *node))block;
- (void)findNodesWithMinDistance:(double)minDistance space:(HSKDTreeSpace)space currentNodes:(NSSet *)currentNodes
					  completion:(void (^)(NSMutableSet *keepNodes, NSMutableSet *addNodes, NSMutableSet *removeNodes))block;

@end
