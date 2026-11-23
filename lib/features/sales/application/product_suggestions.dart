import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Search suggestions for the Sell screen (word-prefix search).
final productSuggestionsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, query) async {
      if (query.trim().isEmpty) return const <Product>[];
      return ref.watch(productRepositoryProvider).searchByName(query);
    });
