import 'package:clean_arc/core/exceptions/exception.dart';
import 'package:clean_arc/core/exceptions/failuers.dart';
import 'package:clean_arc/core/platform/networrk_info.dart';
import 'package:clean_arc/features/number_trivia/data/datasources/number_trivia_locale_data_source%20copy.dart';
import 'package:clean_arc/features/number_trivia/data/datasources/number_trivia_remote_data_source.dart';
import 'package:clean_arc/features/number_trivia/data/models/number_trivia_model.dart';
import 'package:clean_arc/features/number_trivia/data/repositories/number_trivia_repository_impl.dart';
import 'package:clean_arc/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'number_trivia_repository_impl_test.mocks.dart';

@GenerateMocks(
    [NumberTriviaRemoteDataSource, NumberTriviaLocaleDataSource, NetworkInfo])
void main() {
  late NumberTriviaRepositoryImpl repositoryImpl;
  late MockNumberTriviaRemoteDataSource mockNumberTriviaRemoteDataSource;
  late MockNumberTriviaLocaleDataSource mockNumberTriviaLocaleDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockNumberTriviaRemoteDataSource = MockNumberTriviaRemoteDataSource();
    mockNumberTriviaLocaleDataSource = MockNumberTriviaLocaleDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repositoryImpl = NumberTriviaRepositoryImpl(
      remoteDataSource: mockNumberTriviaRemoteDataSource,
      localeDataSource: mockNumberTriviaLocaleDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group("get concrete number trivia", () {
    const tNumber = 1;
    const tNumberTriviaModel = NumberTriviaModel(number: tNumber, text: "test");
    const NumberTrivia tNumberTrivia = tNumberTriviaModel;
    test('should check if the device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockNumberTriviaRemoteDataSource.getConcreteNumberTrivia(tNumber))
          .thenAnswer((_) async => tNumberTriviaModel);
      // act
      repositoryImpl.getConcreteNumberTrivia(tNumber);
      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group("device is online", () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test(
          'should return remote data when the call to remote to data source is success',
          () async {
        // arrange
        when(mockNumberTriviaRemoteDataSource.getConcreteNumberTrivia(any))
            .thenAnswer((realInvocation) async => tNumberTriviaModel);
        // act
        final result = await repositoryImpl.getConcreteNumberTrivia(tNumber);
        // assert

        verify(
            mockNumberTriviaRemoteDataSource.getConcreteNumberTrivia(tNumber));
        expect(result, equals(const Right(tNumberTrivia)));
      });
      test(
          'should cached the data lacally when the call to remote to data source is success',
          () async {
        // arrange
        when(mockNumberTriviaRemoteDataSource.getConcreteNumberTrivia(any))
            .thenAnswer((realInvocation) async => tNumberTriviaModel);
        // act
        final result = await repositoryImpl.getConcreteNumberTrivia(tNumber);
        // assert

        verify(
            mockNumberTriviaRemoteDataSource.getConcreteNumberTrivia(tNumber));
        verify(mockNumberTriviaLocaleDataSource
            .cacheNumberTrivia(tNumberTriviaModel));
      });

      test(
          'should return server failure when the call to remote to data source is unsuccess',
          () async {
        // arrange
        when(mockNumberTriviaRemoteDataSource.getConcreteNumberTrivia(any))
            .thenThrow(ServerException());
        // act
        final result = await repositoryImpl.getConcreteNumberTrivia(tNumber);
        // assert

        verify(
            mockNumberTriviaRemoteDataSource.getConcreteNumberTrivia(tNumber));
        verifyZeroInteractions(mockNumberTriviaLocaleDataSource);
        expect(result, equals(Left(ServerFailure())));
      });
    });

    group("device is offline", () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test(
          'should return last cached locally data when the cache data is present',
          () async {
        // arrange
        when(mockNumberTriviaLocaleDataSource.getLastNumberTrivia())
            .thenAnswer((realInvocation) async => tNumberTriviaModel);
        // act
        final result = await repositoryImpl.getConcreteNumberTrivia(tNumber);
        // assert
        verifyZeroInteractions(mockNumberTriviaRemoteDataSource);
        verify(mockNumberTriviaLocaleDataSource.getLastNumberTrivia());
        expect(result, const Right(tNumberTrivia));
      });
    });
  });
}
