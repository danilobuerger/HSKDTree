//
//  HSKDTree.m
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

#import "HSKDTree.h"

@interface HSKDTree ()

@property (nonatomic) unsigned char dimensions;
@property (nonatomic) Class innerNodeClass;

@property (nonatomic, strong) HSKDTreeNode *rootNode;

@end

@interface HSKDTreeNode ()

@property (nonatomic) NSUInteger depth;
@property (nonatomic, weak) HSKDTreeInnerNode *parentNode;

@end

@interface HSKDTreeInnerNode ()

@property (nonatomic) NSUInteger leafsCount;
@property (nonatomic) HSKDTreeLine line;

@property (nonatomic, strong) HSKDTreeNode *leftNode;
@property (nonatomic, strong) HSKDTreeNode *rightNode;

@end

@implementation HSKDTree

#pragma mark - Initialization methods

- (id)init {
	NSAssert(NO, @"Please call the designated initializer.");
	
	return nil;
}

- (id)initWithDimensions:(unsigned char)dimensions innerNodeClass:(Class)innerNodeClass {
	NSParameterAssert(dimensions >= 2);
	NSParameterAssert(innerNodeClass == NULL || [innerNodeClass isSubclassOfClass:[HSKDTreeInnerNode class]]);
	
	self = [super init];
	
	if (self) {
		self.dimensions = dimensions;
		self.innerNodeClass = innerNodeClass ?: [HSKDTreeInnerNode class];
	}
	
	return self;
}

+ (instancetype)treeWithDimensions:(unsigned char)dimensions {
	return [[self alloc] initWithDimensions:dimensions innerNodeClass:NULL];
}

+ (instancetype)treeWithDimensions:(unsigned char)dimensions innerNodeClass:(Class)innerNodeClass {
	return [[self alloc] initWithDimensions:dimensions innerNodeClass:innerNodeClass];
}

#pragma mark - Custom methods

- (void)constructTreeWithLeafNodes:(NSArray *)leafNodes completion:(void (^)(HSKDTreeNode *rootNode))block {	
	static dispatch_queue_t dispatchQueue = nil;
	static dispatch_group_t dispatchGroup = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dispatchQueue = dispatch_queue_create("de.hmspl.kdtree.constructTreeQueue", DISPATCH_QUEUE_CONCURRENT);
		dispatchGroup = dispatch_group_create();
	});
	
	__block HSKDTreeNode *rootNode = nil;
	
	dispatch_group_enter(dispatchGroup);
	dispatch_async(dispatchQueue, ^{
		rootNode = HS_constructTree(leafNodes, self.innerNodeClass, self.dimensions, 0, 0, nil, dispatchQueue, dispatchGroup);
		dispatch_group_leave(dispatchGroup);
	});
	
	dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
		self.rootNode = rootNode;
		
		if (block) {
			block(rootNode);
		}
	});
}

- (void)findNearestNeighborToPoint:(HSKDTreePoint)point completion:(void (^)(HSKDTreeLeafNode *node))block {
	static dispatch_queue_t dispatchQueue = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dispatchQueue = dispatch_queue_create("de.hmspl.kdtree.findNearestNeighborQueue", DISPATCH_QUEUE_SERIAL);
	});
	
	dispatch_async(dispatchQueue, ^{
		HSKDTreeLeafNode *node = HS_findNearestNeighborToPoint(self.rootNode, point, nil, DBL_MAX);
		
		if (block) {
			dispatch_async(dispatch_get_main_queue(), ^{
				block(node);
			});
		}
	});
}

- (void)findNodesWithMinDistance:(double)minDistance space:(HSKDTreeSpace)space currentNodes:(NSSet *)currentNodes
					  completion:(void (^)(NSMutableSet *keepNodes, NSMutableSet *addNodes, NSMutableSet *removeNodes))block {
	
	static dispatch_queue_t dispatchQueue = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dispatchQueue = dispatch_queue_create("de.hmspl.kdtree.findNodesQueue", DISPATCH_QUEUE_SERIAL);
	});
	
	HSKDTreeSpace spaceCopy = HSKDTreeCopySpace(space);
	
	dispatch_async(dispatchQueue, ^{
		NSMutableSet *keepNodes = [NSMutableSet set];
		NSMutableSet *addNodes = [NSMutableSet set];
		NSMutableSet *removeNodes = [currentNodes mutableCopy];
		
		// TODO: Allow leaf root node
		
		if ([self.rootNode isKindOfClass:[HSKDTreeInnerNode class]]) {
			HS_findNodesWithMinDistance((HSKDTreeInnerNode *) self.rootNode, self.dimensions,
										minDistance, spaceCopy, keepNodes, addNodes, removeNodes);
		}
		
		HSKDTreeReleaseSpace(spaceCopy);
		
		if (block) {
			dispatch_async(dispatch_get_main_queue(), ^{
				block(keepNodes, addNodes, removeNodes);
			});
		}
	});
}

#pragma mark - Private methods

HSKDTreeNode * HS_constructTree(NSArray *leafNodes, Class innerNodeClass, unsigned char dimensions,
								unsigned char currentDimension, NSUInteger depth, HSKDTreeInnerNode *parentNode,
								dispatch_queue_t dispatchQueue, dispatch_group_t dispatchGroup) {
	
	// Check for empty or single leafNodes
	
	if (leafNodes == nil) {
		return nil;
	}
	
	NSUInteger leafsCount = leafNodes.count;
	if (leafsCount == 0) {
		return nil;
	} else if (leafsCount == 1) {
		id leafNodeObject = [leafNodes lastObject];
		NSCAssert([leafNodeObject isKindOfClass:[HSKDTreeLeafNode class]], @"Leaf node must be kind of class HSKDTreeLeafNode.");
		
		HSKDTreeLeafNode *leafNode = (HSKDTreeLeafNode *) leafNodeObject;
		leafNode.depth = depth;
		leafNode.parentNode = parentNode;
		
		return leafNode;
	}
	
	// >= 2 leafNodes left, constructing inner node
	
	HSKDTreeInnerNode *innerNode = [[innerNodeClass alloc] init];
	innerNode.depth = depth;
	innerNode.parentNode = parentNode;
	innerNode.leafsCount = leafsCount;
	
	// Calculate node line
	
	HSKDTreeLine line = HSKDTreeLineConstruct;
	line.dimension = currentDimension;
	
	for (id leafNodeObject in leafNodes) {
		NSCAssert([leafNodeObject isKindOfClass:[HSKDTreeLeafNode class]], @"Leaf node must be kind of class HSKDTreeLeafNode.");
		
		HSKDTreeLeafNode *leafNode = (HSKDTreeLeafNode *) leafNodeObject;
		double pointComponent = HSKDTreePointComponent(leafNode.point, currentDimension);
		line.average += pointComponent;
		
		if (pointComponent < line.low) {
			line.low = pointComponent;
		}
		
		if (pointComponent > line.high) {
			line.high = pointComponent;
		}
	}
	
	line.average = line.average / leafsCount;
	line.length = fabs(line.high - line.low);
	
	innerNode.line = line;
	
	// Split leafNodes into left and right
	
	NSMutableArray *leftLeafNodes = [NSMutableArray array];
	NSMutableArray *rightLeafNodes = [NSMutableArray array];
	
	for (HSKDTreeLeafNode *leafNode in leafNodes) {
		double pointComponent = HSKDTreePointComponent(leafNode.point, currentDimension);
		
		if (fabs(pointComponent - line.average) < FLT_EPSILON) {
			if (leftLeafNodes.count == 0) {
				[leftLeafNodes addObject:leafNode];
			} else {
				[rightLeafNodes addObject:leafNode];
			}
		} else if (pointComponent < line.average) {
			[leftLeafNodes addObject:leafNode];
		} else {
			[rightLeafNodes addObject:leafNode];
		}
	}
	
	// Recurse into left and right nodes
	
	NSCAssert(leftLeafNodes.count >= 1, @"Left leaf nodes array must contain at least one node.");
	NSCAssert(rightLeafNodes.count >= 1, @"Right leaf nodes array must contain at least one node.");
	
	currentDimension = (currentDimension + 1) % dimensions;
	depth++;
	
	if (dispatchQueue && dispatchGroup) {
		dispatch_group_enter(dispatchGroup);
		dispatch_async(dispatchQueue, ^{
			innerNode.rightNode = HS_constructTree(rightLeafNodes, innerNodeClass, dimensions,
												   currentDimension, depth, parentNode, NULL, NULL);
			
			NSCAssert(innerNode.rightNode, @"Right node may not be empty.");
			
			dispatch_group_leave(dispatchGroup);
		});
	} else {
		innerNode.rightNode = HS_constructTree(rightLeafNodes, innerNodeClass, dimensions,
											   currentDimension, depth, parentNode, NULL, NULL);
		
		NSCAssert(innerNode.rightNode, @"Right node may not be empty.");
	}
	
	innerNode.leftNode = HS_constructTree(leftLeafNodes, innerNodeClass, dimensions, currentDimension, depth, parentNode, NULL, NULL);
	NSCAssert(innerNode.leftNode, @"Left node may not be empty.");
	
	return innerNode;
}

HSKDTreeLeafNode * HS_findNearestNeighborToPoint(HSKDTreeNode *node, HSKDTreePoint point,
												 HSKDTreeLeafNode *nearestNode, double nearestDistance) {
	
    if ([node isKindOfClass:[HSKDTreeLeafNode class]]) {
        HSKDTreeLeafNode *leafNode = (HSKDTreeLeafNode *) node;
        
        double distance = [leafNode squaredDistanceToPoint:point];
        return distance < nearestDistance ? leafNode : nearestNode;
    } else {
		NSCAssert([node isKindOfClass:[HSKDTreeInnerNode class]], @"Inner node must be kind of class HSKDTreeInnerNode.");
        HSKDTreeInnerNode *innerNode = (HSKDTreeInnerNode *) node;
        
		double pointComponent = HSKDTreePointComponent(point, innerNode.line.dimension);
		double average = innerNode.line.average;
		
		if (nearestDistance == DBL_MAX) {
			if (pointComponent <= average) {
				nearestNode = HS_findNearestNeighborToPoint(innerNode.leftNode, point, nearestNode, nearestDistance);
				nearestDistance = [nearestNode squaredDistanceToPoint:point];
				
				if (pointComponent + nearestDistance > average) {
					nearestNode = HS_findNearestNeighborToPoint(innerNode.rightNode, point, nearestNode, nearestDistance);
				}
			} else {
				nearestNode = HS_findNearestNeighborToPoint(innerNode.rightNode, point, nearestNode, nearestDistance);
				nearestDistance = [nearestNode squaredDistanceToPoint:point];
				
				if (pointComponent - nearestDistance <= average) {
					nearestNode = HS_findNearestNeighborToPoint(innerNode.leftNode, point, nearestNode, nearestDistance);
				}
			}
		} else {
			if (pointComponent - nearestDistance <= average) {
				nearestNode = HS_findNearestNeighborToPoint(innerNode.leftNode, point, nearestNode, nearestDistance);
				nearestDistance = [nearestNode squaredDistanceToPoint:point];
				
				if (pointComponent + nearestDistance > average) {
					nearestNode = HS_findNearestNeighborToPoint(innerNode.rightNode, point, nearestNode, nearestDistance);
				}
			}
		}
	}
	
    return nearestNode;
}

void HS_findNodesWithMinDistance(HSKDTreeInnerNode *node, unsigned char dimensions, double minDistance, HSKDTreeSpace space,
								 NSMutableSet *keepNodes, NSMutableSet *addNodes, NSMutableSet *removeNodes) {
	
	double lowPointComponent = HSKDTreePointComponent(space.lowPoint, node.line.dimension);
	double highPointComponent = HSKDTreePointComponent(space.highPoint, node.line.dimension);

	if (node.line.high < lowPointComponent || node.line.low > highPointComponent) {
		return;
	}
	
	BOOL isLeftNodeInner = [node.leftNode isKindOfClass:[HSKDTreeInnerNode class]];
	BOOL isRightNodeInner = [node.rightNode isKindOfClass:[HSKDTreeInnerNode class]];
	
	unsigned char nextDimension = (node.line.dimension + 1) % dimensions;
	
	// Check if left and right nodes are leafs.
	// If yes, add them (decluster) if line or distance between those nodes is greater or equal to minDistance.
	
	if (!isLeftNodeInner && !isRightNodeInner) {
		NSCAssert([node.leftNode isKindOfClass:[HSKDTreeLeafNode class]], @"Leaf node must be kind of class HSKDTreeLeafNode.");
		HSKDTreeLeafNode *leftLeafNode = (HSKDTreeLeafNode *) node.leftNode;
		
		NSCAssert([node.rightNode isKindOfClass:[HSKDTreeLeafNode class]], @"Leaf node must be kind of class HSKDTreeLeafNode.");
		HSKDTreeLeafNode *rightLeafNode = (HSKDTreeLeafNode *) node.rightNode;
		
		double leftLeafNodePointComponent = HSKDTreePointComponent(leftLeafNode.point, nextDimension);
		double rightLeafNodePointComponent = HSKDTreePointComponent(rightLeafNode.point, nextDimension);
		
		double distance = fabs(leftLeafNodePointComponent - rightLeafNodePointComponent);
		
		if (node.line.length >= minDistance || distance >= minDistance) {
			HS_foundNode(node.leftNode, keepNodes, addNodes, removeNodes);
			HS_foundNode(node.rightNode, keepNodes, addNodes, removeNodes);
			
			return;
		}
	}
	
	// Add self (cluster) if line is smaller than minDistance
	
	if (node.line.length < minDistance) {
		HS_foundNode(node, keepNodes, addNodes, removeNodes);
		
		return;
	}
	
	// Check if left node is inner and right node is leaf. See method.
	
	if (isLeftNodeInner && !isRightNodeInner) {
		HSKDTreeInnerNode *leftInnerNode = (HSKDTreeInnerNode *) node.leftNode;
		
		NSCAssert([node.rightNode isKindOfClass:[HSKDTreeLeafNode class]], @"Leaf node must be kind of class HSKDTreeLeafNode.");
		HSKDTreeLeafNode *rightLeafNode = (HSKDTreeLeafNode *) node.rightNode;
		
		HS_findNodesWithMinDistanceInner(node, dimensions, minDistance, space, keepNodes, addNodes,
										 removeNodes, leftInnerNode, rightLeafNode);
		
		return;
	}
	
	// Check if right node is inner and left node is leaf. See method.
	
	if (isRightNodeInner && !isLeftNodeInner) {
		NSCAssert([node.leftNode isKindOfClass:[HSKDTreeLeafNode class]], @"Leaf node must be kind of class HSKDTreeLeafNode.");
		HSKDTreeLeafNode *leftLeafNode = (HSKDTreeLeafNode *) node.leftNode;
		
		HSKDTreeInnerNode *rightInnerNode = (HSKDTreeInnerNode *) node.rightNode;
		
		HS_findNodesWithMinDistanceInner(node, dimensions, minDistance, space, keepNodes, addNodes,
										 removeNodes, rightInnerNode, leftLeafNode);
		
		return;
	}
	
	// At this point left and right nodes are both inner.
	
	if (isLeftNodeInner && isRightNodeInner) {
		HSKDTreeInnerNode *leftInnerNode = (HSKDTreeInnerNode *) node.leftNode;
		HSKDTreeInnerNode *rightInnerNode = (HSKDTreeInnerNode *) node.rightNode;
		
		double distance = fabs(leftInnerNode.line.average - rightInnerNode.line.average);
		
		// If the distance between both inner nodes line average is smaller than the minDistance, add self (cluster).
		// Else check each inner node. See method.
		
		if (distance < minDistance && (leftInnerNode.line.length < minDistance || rightInnerNode.line.length < minDistance)) {
			HS_foundNode(node, keepNodes, addNodes, removeNodes);
		} else {
			HS_findNodesWithMinDistance(leftInnerNode, dimensions, minDistance, space, keepNodes, addNodes, removeNodes);
			HS_findNodesWithMinDistance(rightInnerNode, dimensions, minDistance, space, keepNodes, addNodes, removeNodes);
		}
	}
}

void HS_findNodesWithMinDistanceInner(HSKDTreeInnerNode *node, unsigned char dimensions, double minDistance, HSKDTreeSpace space,
									  NSMutableSet *keepNodes, NSMutableSet *addNodes, NSMutableSet *removeNodes,
									  HSKDTreeInnerNode *innerNode, HSKDTreeLeafNode *leafNode) {
	
	unsigned char nextDimension = (node.line.dimension + 1) % dimensions;
	double leafNodePointComponent = HSKDTreePointComponent(leafNode.point, nextDimension);
	double distance = fabs(innerNode.line.average - leafNodePointComponent);
	
	// If the offset between the inner nodes line average and leaf node point component is smaller than the minDistance, add self (cluster).
	// Else check the inner node (see method) and add the leaf node (decluster).
	
	if (distance < minDistance) {
		HS_foundNode(node, keepNodes, addNodes, removeNodes);
	} else {
		HS_findNodesWithMinDistance(innerNode, dimensions, minDistance, space, keepNodes, addNodes, removeNodes);
		HS_foundNode(leafNode, keepNodes, addNodes, removeNodes);
	}
}

void HS_foundNode(HSKDTreeNode *node, NSMutableSet *keepNodes, NSMutableSet *addNodes, NSMutableSet *removeNodes) {
	if ([removeNodes containsObject:node]) {
		[removeNodes removeObject:node];
		[keepNodes addObject:node];
	} else {
		[addNodes addObject:node];
	}
}

@end