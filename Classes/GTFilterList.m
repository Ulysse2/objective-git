//
//  GTFilterList.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2014-02-20.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFilterList.h"

#import "GTBlob.h"
#import "GTRepository.h"
#import "NSError+Git.h"

@interface GTFilterList ()

@property (nonatomic, assign, readonly) git_filter_list *git_filter_list;

@end

@implementation GTFilterList

#pragma mark Lifecycle

- (instancetype)initWithGitFilterList:(git_filter_list *)filterList {
	NSParameterAssert(filterList != NULL);

	self = [super init];
	if (self == nil) return nil;

	_git_filter_list = filterList;

	return self;
}

#pragma mark Application

- (NSData *)applyToData:(NSData *)inputData error:(NSError **)error {
	NSParameterAssert(inputData != nil);

	git_buf input = (git_buf){
		.ptr = (void *)inputData.bytes,
		.asize = 0,
		.size = inputData.length,
	};

	git_buf output;
	int gitError = git_filter_list_apply_to_data(&output, self.git_filter_list, &input);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to apply filter list to data buffer"];
		return nil;
	}

	// TODO: Reuse output buffers if possible.
	NSData *data = [[NSData alloc] initWithBytes:output.ptr length:output.size];
	git_buf_free(&output);

	return data;
}

- (NSData *)applyToPath:(NSString *)relativePath inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(relativePath != nil);
	NSParameterAssert(repository != nil);

	git_buf output;
	int gitError = git_filter_list_apply_to_file(&output, self.git_filter_list, repository.git_repository, relativePath.fileSystemRepresentation);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to apply filter list to %@", relativePath];
		return nil;
	}

	// TODO: Reuse output buffers if possible.
	NSData *data = [[NSData alloc] initWithBytes:output.ptr length:output.size];
	git_buf_free(&output);

	return data;
}

- (NSData *)applyToBlob:(GTBlob *)blob error:(NSError **)error {
	NSParameterAssert(blob != nil);

	git_buf output;
	int gitError = git_filter_list_apply_to_blob(&output, self.git_filter_list, blob.git_blob);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to apply filter list to blob %@", blob.OID];
		return nil;
	}

	// TODO: Reuse output buffers if possible.
	NSData *data = [[NSData alloc] initWithBytes:output.ptr length:output.size];
	git_buf_free(&output);

	return data;
}

@end
