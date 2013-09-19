//
//  HSKDTreeDefines.h
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

#ifndef HSKDTREEDEFINES_H_
#define HSKDTREEDEFINES_H_

#pragma mark - Line

typedef struct {
	NSUInteger dimension;
	double average;
	double low;
	double high;
	double length;
} HSKDTreeLine;

extern const HSKDTreeLine HSKDTreeLineZero;
extern const HSKDTreeLine HSKDTreeLineConstruct;

static inline HSKDTreeLine HSKDTreeLineMake(NSUInteger dimension, double average, double low, double high, double length) {
	HSKDTreeLine line;
	line.dimension = dimension;
	line.average = average;
	line.low = low;
	line.high = high;
	line.length = length;
	
	return line;
}

extern NSString * NSStringFromHSKDTreeLine(HSKDTreeLine line);

#pragma mark - Point

typedef struct {
	NSUInteger dimensions;
	double *components;
} HSKDTreePoint;

static inline double HSKDTreePointComponent(HSKDTreePoint point, NSUInteger dimension) {
	NSCParameterAssert(point.dimensions > dimension);
	NSCParameterAssert(point.components != NULL);
	
	return point.components[dimension];
}

extern HSKDTreePoint HSKDTreeCreatePoint(NSUInteger dimensions, ...);
extern HSKDTreePoint HSKDTreeCopyPoint(HSKDTreePoint point);
extern void HSKDTreeReleasePoint(HSKDTreePoint point);
extern NSString * NSStringFromHSKDTreePoint(HSKDTreePoint point);

#pragma mark - Space

typedef struct {
	HSKDTreePoint lowPoint;
	HSKDTreePoint highPoint;
} HSKDTreeSpace;

extern HSKDTreeSpace HSKDTreeCreateSpace(NSUInteger dimensions, ...);
extern HSKDTreeSpace HSKDTreeCopySpace(HSKDTreeSpace space);
extern void HSKDTreeReleaseSpace(HSKDTreeSpace space);
extern BOOL HSKDTreeSpaceContainsPoint(HSKDTreeSpace space, HSKDTreePoint point);
extern NSString * NSStringFromHSKDTreeSpace(HSKDTreeSpace space);

#endif
