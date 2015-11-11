#include <cuda_runtime.h>
#include <stdio.h>
 
__global__ void addKernel( int* c, constint* a, const int* b )
{
         inti = threadIdx.x;
         c[i]= a[i] + b[i];
}
 
cudaError_t CUDA_Add( const int* a, constint* b, int* out, int size )
{
         int*dev_a;
         int*dev_b;
         int*dev_c;
 
         //1、设置设备
         cudaError_tcudaStatus = cudaSetDevice( 0 );
 
         switch( true )
         {
         default:
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf(stderr, "调用cudaSetDevice()函数失败！" );
                            returncudaStatus;
                   }
 
                   //2、分配显存空间
                   cudaStatus= cudaMalloc( (void**)&dev_a, size * sizeof(int) );
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf(stderr, "调用cudaMalloc()函数初始化显卡中a数组时失败！" );
                            break;
                   }
 
                   cudaStatus= cudaMalloc( (void**)&dev_b, size * sizeof(int) );
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf(stderr, "调用cudaMalloc()函数初始化显卡中b数组时失败！" );
                            break;
                   }
 
                   cudaStatus= cudaMalloc( (void**)&dev_c, size * sizeof(int) );
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf(stderr, "调用cudaMalloc()函数初始化显卡中c数组时失败！" );
                            break;
                   }
 
                   //3、将宿主程序数据复制到显存中
                   cudaStatus= cudaMemcpy( dev_a, a, size * sizeof( int ), cudaMemcpyHostToDevice );
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf( stderr, "调用cudaMemcpy()函数初始化宿主程序数据a数组到显卡时失败！");
                            break;
                   }
                   cudaStatus= cudaMemcpy( dev_b, b, size * sizeof( int ), cudaMemcpyHostToDevice );
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf(stderr, "调用cudaMemcpy()函数初始化宿主程序数据b数组到显卡时失败！" );
                            break;
                   }
 
                   //4、执行程序，宿主程序等待显卡执行完毕
                   addKernel<<<1,size>>>( dev_c, dev_a, dev_b );
 
                   //5、查询内核初始化的时候是否出错
                   cudaStatus= cudaGetLastError( );
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf(stderr, "显卡执行程序时失败！" );
                            break;
                   }
 
                   //6、与内核同步等待执行完毕
                   cudaStatus= cudaDeviceSynchronize( );
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf(stderr, "在与内核同步的过程中发生问题！" );
                            break;
                   }
 
                   //7、获取数据
                   cudaStatus= cudaMemcpy( out, dev_c, size * sizeof( int ), cudaMemcpyDeviceToHost );
                   if( cudaStatus != cudaSuccess )
                   {
                            fprintf(stderr, "在将结果数据从显卡复制到宿主程序中失败！" );
                            break;
                   }
         }
 
         cudaFree(dev_c );
         cudaFree(dev_a );
         cudaFree(dev_b );
 
         returncudaStatus;
}
 
int main( int argc, char** argv )
{
         constint arraySize = 5;
         constint a[arraySize] = { 1, 2, 3, 4, 5 };
         constint b[arraySize] = { 10, 20, 30, 40, 50 };
         intc[arraySize] = { 0 };
 
         cudaError_tcudaStatus;
 
         cudaStatus= CUDA_Add( a, b, c, arraySize );
 
         printf("运算结果是：\nc数组[%d, %d, %d, %d, %d]\n",
                   c[0],c[1], c[2], c[3], c[4] );
 
         cudaStatus= cudaDeviceReset( );
         if( cudaStatus != cudaSuccess )
         {
                   fprintf(stderr, "调用cudaDeviceReset()函数失败！" );
                   return1;
         }
 
         return0;
}
