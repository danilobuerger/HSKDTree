//
//  HSKDTreeDefines.m
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

#import "HSKDTreeDefines.h"

#pragma mark - Line

const HSKDTreeLine HSKDTreeLineZero = {0, 0.0, 0.0, 0.0, 0.0};
const HSKDTreeLine HSKDTreeLineConstruct = {0, 0.0, DBL_MAX, DBL_MIN, 0.0};

NSString * NSStringFromHSKDTreeLine(HSKDTreeLine line) {
	return [NSString stringWithFormat:@"line: { dimension: %d, average: %f, low: %f, high: %f, length: %f }",
			line.dimension, line.average, line.low, line.high, line.length];
}

#pragma mark - Point

HSKDTreePoint HSKDTreeCreatePointV(unsigned char dimensions, va_list arguments) {
	NSCParameterAssert(dimensions >= 2);
	NSCParameterAssert(arguments != NULL);
	
	HSKDTreePoint point;
	point.dimensions = dimensions;
	
	size_t componentsSize = dimensions * sizeof(double);
	point.components = malloc(componentsSize);
	
	if (point.components) {
		memcpy(point.components, arguments, componentsSize);
	}
	
	return point;
}

HSKDTreePoint HSKDTreeCreatePoint(unsigned char dimensions, ...) {
	va_list arguments;
	va_start(arguments, dimensions);
	
	HSKDTreePoint point = HSKDTreeCreatePointV(dimensions, arguments);
	
	va_end(arguments);
	
	return point;
}

HSKDTreePoint HSKDTreeCopyPoint(HSKDTreePoint point) {
	HSKDTreePoint newPoint;
	newPoint.dimensions = point.dimensions;
	
	size_t componentsSize = newPoint.dimensions * sizeof(double);
	newPoint.components = malloc(componentsSize);
	
	if (newPoint.components) {
		memcpy(newPoint.components, point.components, componentsSize);
	}
	
	return newPoint;
}

void HSKDTreeReleasePoint(HSKDTreePoint point) {
	free(point.components);
}

NSString * NSStringFromHSKDTreePoint(HSKDTreePoint point) {
	NSMutableString *string = [NSMutableString stringWithString:@"point: {"];
	
	for (unsigned char d = 0; d < point.dimensions; d++) {
		if (d == 0) {
			[string appendFormat:@" %f", HSKDTreePointComponent(point, d)];
		} else {
			[string appendFormat:@", %f", HSKDTreePointComponent(point, d)];
		}
	}
	
	[string appendString:@" }"];
	
	return string;
}

#pragma mark - Space

HSKDTreeSpace HSKDTreeCreateSpace(unsigned char dimensions, ...) {
	HSKDTreeSpace space;
	
	va_list arguments;
	va_start(arguments, dimensions);
	
	size_t componentsSize = dimensions * sizeof(double);
	space.lowPoint = HSKDTreeCreatePointV(dimensions, arguments);
	space.highPoint = HSKDTreeCreatePointV(dimensions, arguments + componentsSize);
	
	va_end(arguments);
	
	return space;
}

HSKDTreeSpace HSKDTreeCopySpace(HSKDTreeSpace space) {
	HSKDTreeSpace newSpace;
	newSpace.lowPoint = HSKDTreeCopyPoint(space.lowPoint);
	newSpace.highPoint = HSKDTreeCopyPoint(space.highPoint);
	
	return newSpace;
}

void HSKDTreeReleaseSpace(HSKDTreeSpace space) {
	free(space.lowPoint.components);
	free(space.highPoint.components);
}

NSString * NSStringFromHSKDTreeSpace(HSKDTreeSpace space) {
	NSString *lowPoint = NSStringFromHSKDTreePoint(space.lowPoint);
	NSString *highPoint = NSStringFromHSKDTreePoint(space.highPoint);
	
	return [NSString stringWithFormat:@"space: { low %@, high %@ }", lowPoint, highPoint];
}
