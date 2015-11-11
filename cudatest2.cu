#include <cuda_runtime.h>
#include <cctype>
#include <cassert>
#include <cstdio>
#include <ctime>

#define DATA_SIZE 1048576
#define THREAD_NUM 256
#ifndef nullptr
#define nullptr 0
#endif

using namespace std;

void GenerateData( int* pData, size_t dataSize )// 产生数据
{
	assert( pData != nullptr );
	for ( size_t i = 0; i < dataSize; i++ )
	{
		srand( i + 3 );
		pData[i] = rand( ) % 100;
	}
}

////////////////////////在设备上运行的内核函数/////////////////////////////
__global__ static void Kernel_SquareSum( int* pIn, size_t* pDataSize,
										int* pOut, clock_t* pElapsed )
{
	// 开始计时
	clock_t startTime = clock( );

	for ( size_t i = 0; i < *pDataSize; ++i )
	{
		*pOut += pIn[i] * pIn[i];
	}

	*pElapsed = clock( ) - startTime;// 结束计时，返回至主程序
}

bool CUDA_SquareSum( int* pOut, clock_t* pElapsed,
					int* pIn, size_t dataSize )
{
	assert( pIn != nullptr );
	assert( pOut != nullptr );

	int* pDevIn = nullptr;
	int* pDevOut = nullptr;
	size_t* pDevDataSize = nullptr;
	clock_t* pDevElasped = nullptr;

	// 1、设置设备
	cudaError_t cudaStatus = cudaSetDevice( 0 );// 只要机器安装了英伟达显卡，那么会调用成功
	if ( cudaStatus != cudaSuccess )
	{
		fprintf( stderr, "调用cudaSetDevice()函数失败！" );
		return false;
	}

	switch ( true )
	{
	default:
		// 2、分配显存空间
		cudaStatus = cudaMalloc( (void**)&pDevIn, dataSize * sizeof( int ) );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "调用cudaMalloc()函数初始化显卡中数组时失败！" );
			break;
		}

		cudaStatus = cudaMalloc( (void**)&pDevOut, sizeof( int ) );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "调用cudaMalloc()函数初始化显卡中返回值时失败！" );
			break;
		}

		cudaStatus = cudaMalloc( (void**)&pDevDataSize, sizeof( size_t ) );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "调用cudaMalloc()函数初始化显卡中数据大小时失败！" );
			break;
		}

		cudaStatus = cudaMalloc( (void**)&pDevElasped, sizeof( clock_t ) );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "调用cudaMalloc()函数初始化显卡中耗费用时变量失败！" );
			break;
		}

		// 3、将宿主程序数据复制到显存中
		cudaStatus = cudaMemcpy( pDevIn, pIn, dataSize * sizeof( int ), cudaMemcpyHostToDevice );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "调用cudaMemcpy()函数初始化宿主程序数据数组到显卡时失败！" );
			break;
		}

		cudaStatus = cudaMemcpy( pDevDataSize, &dataSize, sizeof( size_t ), cudaMemcpyHostToDevice );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "调用cudaMemcpy()函数初始化宿主程序数据大小到显卡时失败！" );
			break;
		}

		// 4、执行程序，宿主程序等待显卡执行完毕
		Kernel_SquareSum<<<1, 1>>>( pDevIn, pDevDataSize, pDevOut, pDevElasped );

		// 5、查询内核初始化的时候是否出错
		cudaStatus = cudaGetLastError( );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "显卡执行程序时失败！" );
			break;
		}

		// 6、与内核同步等待执行完毕
		cudaStatus = cudaDeviceSynchronize( );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "在与内核同步的过程中发生问题！" );
			break;
		}

		// 7、获取数据
		cudaStatus = cudaMemcpy( pOut, pDevOut, sizeof( int ), cudaMemcpyDeviceToHost );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "在将结果数据从显卡复制到宿主程序中失败！" );
			break;
		}

		cudaStatus = cudaMemcpy( pElapsed, pDevElasped, sizeof( clock_t ), cudaMemcpyDeviceToHost );
		if ( cudaStatus != cudaSuccess )
		{
			fprintf( stderr, "在将耗费用时数据从显卡复制到宿主程序中失败！" );
			break;
		}

		cudaFree( pDevIn );
		cudaFree( pDevOut );
		cudaFree( pDevDataSize );
		cudaFree( pDevElasped );
		return true;
	}

	cudaFree( pDevIn );
	cudaFree( pDevOut );
	cudaFree( pDevDataSize );
	cudaFree( pDevElasped );
	return false;
}

int main( int argc, char** argv )// 函数的主入口
{
	int* pData = nullptr;
	int* pResult = nullptr;
	clock_t* pElapsed = nullptr;

	// 使用CUDA内存分配器分配host端
	cudaError_t cudaStatus = cudaMallocHost( &pData, DATA_SIZE * sizeof( int ) );
	if ( cudaStatus != cudaSuccess )
	{
		fprintf( stderr, "在主机中分配资源失败！" );
		return 1;
	}

	cudaStatus = cudaMallocHost( &pResult, sizeof( int ) );
	if ( cudaStatus != cudaSuccess )
	{
		fprintf( stderr, "在主机中分配资源失败！" );
		return 1;
	}

	cudaStatus = cudaMallocHost( &pElapsed, sizeof( clock_t ) );
	if ( cudaStatus != cudaSuccess )
	{
		fprintf( stderr, "在主机中分配资源失败！" );
		return 1;
	}

	GenerateData( pData, DATA_SIZE );// 通过随机数产生数据
	CUDA_SquareSum( pResult, pElapsed, pData, DATA_SIZE );// 执行平方和

	// 判断是否溢出
	char* pOverFlow = nullptr;
	if ( *pResult < 0 ) pOverFlow = "（溢出）";
	else pOverFlow = "";

	// 显示基准测试
	printf( "用CUDA计算平方和的结果是：%d%s\n耗费用时：%d\n",
		*pResult, pOverFlow, *pElapsed );

	cudaDeviceProp prop;
	if ( cudaGetDeviceProperties( &prop, 0 ) == cudaSuccess )
	{
		clock_t actualTime = *pElapsed / clock_t( prop.clockRate );
		printf( "实际执行时间为：%dms\n", actualTime );
		printf( "带宽为：%.2fMB/s\n",
			float( DATA_SIZE * sizeof( int ) >> 20 ) * 1000.0f / float( actualTime ) );
		printf( "GPU设备型号：%s\n", prop.name );
	}

	cudaFreeHost( pData );
	cudaFreeHost( pResult );
	cudaFreeHost( pElapsed );


	return 0;
}
