import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/utils/formatters.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/form_page.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/products/application/product_providers.dart';
import 'package:tindascan/features/products/domain/internal_code.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/features/products/domain/product_validators.dart';
import 'package:tindascan/features/products/presentation/product_labels.dart';
import 'package:tindascan/features/settings/application/settings_providers.dart';
import 'package:tindascan/shared/models/product.dart';

/// Add (no [productId]) or edit a product. Owner only.
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({this.productId, this.initialBarcode, super.key});

  final String? productId;

  /// Prefilled from a "Product not found → Add this product" shortcut.
  final String? initialBarcode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = productId;
    if (id == null) {
      final threshold = ref.watch(
        storeSettingsProvider.select(
          (s) =>
              s.value?.defaultLowStockThreshold ??
              AppConstants.defaultLowStockThreshold,
        ),
      );
      return Scaffold(
        appBar: AppBar(title: Text(l10n.productNewTitle)),
        body: _ProductForm(
          initial: null,
          initialBarcode: initialBarcode,
          defaultThreshold: threshold,
        ),
      );
    }
    final product = ref.watch(productByIdProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productEditTitle)),
      body: AsyncValueView<Product?>(
        value: product,
        onRetry: () => ref.invalidate(productByIdProvider(id)),
        isEmpty: (p) => p == null,
        emptyMessage: l10n.errorNotFound,
        data: (p) => _ProductForm(
          // Key by id so a live update does not reset half-typed edits.
          key: ValueKey(p!.id),
          initial: p,
          defaultThreshold: p.lowStockThreshold,
        ),
      ),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({
    required this.initial,
    required this.defaultThreshold,
    this.initialBarcode,
    super.key,
  });

  final Product? initial;
  final String? initialBarcode;
  final int defaultThreshold;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final Product? _initial = widget.initial;
  late final TextEditingController _name = TextEditingController(
    text: _initial?.name,
  );
  late final TextEditingController _barcode = TextEditingController(
    text: _initial?.barcode ?? widget.initialBarcode,
  );
  late final TextEditingController _price = TextEditingController(
    text: _initial == null ? '' : Money.toInput(_initial.unitPriceCentavos),
  );
  late final TextEditingController _cost = TextEditingController(
    text: _initial == null ? '' : Money.toInput(_initial.costPriceCentavos),
  );
  late final TextEditingController _stock = TextEditingController(
    text: '${_initial?.stockQty ?? 0}',
  );
  late final TextEditingController _threshold = TextEditingController(
    text: '${_initial?.lowStockThreshold ?? widget.defaultThreshold}',
  );
  late ProductCategory _category = ProductCategory.fromKey(_initial?.category);
  late DateTime? _expiry = _initial?.expiryDate;
  late bool _noBarcode = _initial != null && !_initial.hasBarcode;

  bool get _isNew => _initial == null;

  @override
  void dispose() {
    for (final c in [_name, _barcode, _price, _cost, _stock, _threshold]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await context.push<String>(AppRoutes.scan);
    if (code != null && mounted) {
      setState(() {
        _noBarcode = false;
        _barcode.text = code;
      });
    }
  }

  void _toggleNoBarcode(bool value) {
    setState(() {
      _noBarcode = value;
      if (value) {
        _barcode.text = InternalCode.generate();
      } else if (InternalCode.isInternal(_barcode.text)) {
        _barcode.clear();
      }
    });
  }

  Future<void> _pickExpiry() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      // Store as Manila midnight of the chosen calendar day.
      setState(
        () => _expiry = DateTime.utc(
          picked.year,
          picked.month,
          picked.day,
        ).subtract(ManilaTime.offset),
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final base = _initial;
    final product = Product(
      id: base?.id ?? '',
      barcode: ProductValidators.normalizeBarcode(_barcode.text),
      name: _name.text.trim(),
      category: _category.key,
      unitPriceCentavos: Money.tryParse(_price.text)!,
      costPriceCentavos: Money.tryParse(_cost.text)!,
      stockQty: base?.stockQty ?? int.parse(_stock.text.trim()),
      lowStockThreshold: int.parse(_threshold.text.trim()),
      expiryDate: _expiry,
      isActive: base?.isActive ?? true,
      hasBarcode: !_noBarcode,
    );
    final id = await ref
        .read(productEditControllerProvider.notifier)
        .save(product, initialStockNote: l10n.productInitialStockNote);
    if (id == null || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.productSaved)));
    if (_isNew) {
      unawaited(router.pushReplacement(AppRoutes.productDetail(id)));
    } else {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(productEditControllerProvider);
    final price = Money.tryParse(_price.text);
    final cost = Money.tryParse(_cost.text);
    final belowCost = price != null && cost != null && price < cost;
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];
    final moneyChars = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

    return FormPage(
      children: [
        if (state case AsyncError(:final error))
          MessageBanner(text: error.toUserMessage(l10n)),
        Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('product-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: AppConstants.maxNameLength,
                decoration: InputDecoration(labelText: l10n.productNameLabel),
                validator: (v) => ProductValidators.name(v).toText(l10n),
              ),
              const FieldGap(),
              TextFormField(
                key: const Key('product-barcode'),
                controller: _barcode,
                readOnly: _noBarcode,
                maxLength: AppConstants.maxBarcodeLength,
                decoration: InputDecoration(
                  labelText: _noBarcode
                      ? l10n.productInternalCode
                      : l10n.productBarcodeLabel,
                  suffixIcon: IconButton(
                    tooltip: l10n.productScanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scan,
                  ),
                ),
                validator: (v) => ProductValidators.barcode(
                  ProductValidators.normalizeBarcode(v ?? ''),
                ).toText(l10n),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.productNoBarcode),
                value: _noBarcode,
                onChanged: _toggleNoBarcode,
              ),
              const FieldGap(),
              DropdownButtonFormField<ProductCategory>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: l10n.productCategoryLabel,
                ),
                items: [
                  for (final c in ProductCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label(l10n))),
                ],
                onChanged: (c) => setState(() => _category = c ?? _category),
              ),
              const FieldGap(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('product-price'),
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: moneyChars,
                      decoration: InputDecoration(
                        labelText: l10n.productPriceLabel,
                      ),
                      validator: (v) => ProductValidators.money(v).toText(l10n),
                    ),
                  ),
                  const SizedBox(width: Gaps.md),
                  Expanded(
                    child: TextFormField(
                      key: const Key('product-cost'),
                      controller: _cost,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: moneyChars,
                      decoration: InputDecoration(
                        labelText: l10n.productCostLabel,
                      ),
                      validator: (v) => ProductValidators.money(v).toText(l10n),
                    ),
                  ),
                ],
              ),
              if (belowCost)
                Padding(
                  padding: const EdgeInsets.only(top: Gaps.sm),
                  child: Text(
                    l10n.productPriceBelowCost,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const FieldGap(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isNew) ...[
                    Expanded(
                      child: TextFormField(
                        key: const Key('product-stock'),
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsOnly,
                        decoration: InputDecoration(
                          labelText: l10n.productInitialStockLabel,
                        ),
                        validator: (v) =>
                            ProductValidators.quantity(v).toText(l10n),
                      ),
                    ),
                    const SizedBox(width: Gaps.md),
                  ],
                  Expanded(
                    child: TextFormField(
                      key: const Key('product-threshold'),
                      controller: _threshold,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnly,
                      decoration: InputDecoration(
                        labelText: l10n.productThresholdLabel,
                      ),
                      validator: (v) =>
                          ProductValidators.threshold(v).toText(l10n),
                    ),
                  ),
                ],
              ),
              if (_isNew)
                Padding(
                  padding: const EdgeInsets.only(top: Gaps.sm),
                  child: Text(
                    l10n.productStockNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const FieldGap(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(l10n.productExpiryLabel),
                subtitle: Text(
                  _expiry == null
                      ? l10n.productNoExpiry
                      : AppFormat.date(context, _expiry!),
                ),
                onTap: _pickExpiry,
                trailing: _expiry == null
                    ? TextButton(
                        onPressed: _pickExpiry,
                        child: Text(l10n.productPickDate),
                      )
                    : IconButton(
                        tooltip: l10n.clear,
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _expiry = null),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gaps.lg),
        PrimaryButton(
          key: const Key('product-save'),
          label: l10n.save,
          isLoading: state.isLoading,
          onPressed: _save,
        ),
      ],
    );
  }
}
