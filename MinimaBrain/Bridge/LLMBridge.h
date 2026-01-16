#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLMBridge : NSObject

/// Initialize the LLM with a model path
- (instancetype)initWithModelPath:(NSString *)path;

/// Check if model is loaded
- (BOOL)isLoaded;

/// Warm up the context
- (void)prefetch;

/// Ingest an image representation (Embeddings or Pixel Buffer)
/// For our "Sovereign" hybrid, this might take the CoreML MultiArray directly usually,
/// but keeping it generic as float* for now.
- (void)ingestImageEmbeddings:(float *)embeddings length:(NSInteger)length;

/// Generate text response
- (NSString *)generateResponseForPrompt:(NSString *)prompt;

@end

NS_ASSUME_NONNULL_END
