#import <Foundation/Foundation.h>


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        uint8 raw[3] = {0xE6, 0x88, 0x91};
        NSMutableData *data = [NSMutableData dataWithBytes:&raw length:3];
        const uint8 *ptr = [data bytes];
        
        NSLog(@"Hello, World! %s -- %@", ptr++, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        UInt64 ret = 0;
//        [data getBytes:&ret length:1];
//        NSData * temp = [data subdataWithRange:NSMakeRange(2, 0)];
        NSLog(@"----- %llu -- %lu, length: %zd", ret, sizeof(float), sizeof(UInt16));
    }
    return 0;
}

