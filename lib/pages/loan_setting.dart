// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jumuiya_yangu/theme/colors.dart';
import '../models/loan_setting.dart';
import '../services/loan_setting_service.dart';

class LoanSettingPage extends StatefulWidget {
  final dynamic jumuiyaId;
  const LoanSettingPage({super.key, required this.jumuiyaId});
  @override
  State<LoanSettingPage> createState() => _LoanSettingPageState();
}

class _LoanSettingPageState extends State<LoanSettingPage> {
  final _loanSettingService = LoanSettingService();
  List<LoanSetting> _loanSettings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _loanSettingService
          .getAllLoanSettingsByJumuiyaId(widget.jumuiyaId);
      setState(() => _loanSettings = settings);
    } catch (e) {
      _showSnackBar('Hitilafu: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddEditBottomSheet({LoanSetting? setting}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoanSettingForm(
        jumuiyaId: widget.jumuiyaId,
        existingSetting: setting,
        onSaved: () {
          _loadAllSettings();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Mipangilio ya Mikopo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAllSettings,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loanSettings.isEmpty
              ? _buildEmptyState()
              : _buildSettingsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBottomSheet(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ongeza Mpango',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        backgroundColor: mainFontColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_suggest_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hakuna mipangilio ya mikopo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bonyeza kitufe cha chini kuongeza',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loanSettings.length,
      itemBuilder: (context, index) {
        final setting = _loanSettings[index];
        return _buildSettingCard(setting, index);
      },
    );
  }

  Widget _buildSettingCard(LoanSetting setting, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddEditBottomSheet(setting: setting),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mainFontColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: mainFontColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            setting.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: setting.shareSaving == 'SHARE'
                                  ? Colors.blue.withOpacity(0.15)
                                  : Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              setting.shareSaving == 'SHARE' ? 'Hisa' : 'Akiba',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: setting.shareSaving == 'SHARE'
                                    ? Colors.blue[800]
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: mainFontColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: mainFontColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[300], height: 1),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoChip(
                      Icons.trending_up_rounded,
                      'Riba',
                      '${setting.interestRate}%',
                      Colors.orange,
                    ),
                    if (setting.multiplier != null)
                      _buildInfoChip(
                        Icons.close_rounded,
                        'Mzidishaji',
                        'x${setting.multiplier}',
                        Colors.purple,
                      ),
                    if (setting.percentage != null)
                      _buildInfoChip(
                        Icons.percent_rounded,
                        'Asilimia',
                        '${setting.percentage}%',
                        Colors.blue,
                      ),
                    _buildInfoChip(
                      Icons.calendar_month_rounded,
                      'Miezi',
                      '${setting.maxPeriodMonths}',
                      Colors.teal,
                    ),
                  ],
                ),
                if (setting.minAmounts != null ||
                    setting.maxAmounts != null ||
                    setting.sharePrice != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        if (setting.minAmounts != null ||
                            setting.maxAmounts != null)
                          _buildDetailRow(
                            Icons.attach_money_rounded,
                            'Kikomo',
                            'Tsh ${setting.minAmounts ?? 0} - ${setting.maxAmounts ?? '∞'}',
                          ),
                        if (setting.sharePrice != null) ...[
                          if (setting.minAmounts != null ||
                              setting.maxAmounts != null)
                            const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.price_change_rounded,
                            'Bei ya Hisa',
                            'Tsh ${setting.sharePrice}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class LoanSettingForm extends StatefulWidget {
  final dynamic jumuiyaId;
  final LoanSetting? existingSetting;
  final VoidCallback onSaved;

  const LoanSettingForm({
    super.key,
    required this.jumuiyaId,
    this.existingSetting,
    required this.onSaved,
  });

  @override
  State<LoanSettingForm> createState() => _LoanSettingFormState();
}

class _LoanSettingFormState extends State<LoanSettingForm> {
  final _formKey = GlobalKey<FormState>();
  final _loanSettingService = LoanSettingService();

  bool _isLoading = false;
  bool _isMultiplier = true;
  bool _hasMinMaxAmounts = false;
  String _shareSaving = 'SAVING';

  final _nameController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _multiplierController = TextEditingController();
  final _percentageController = TextEditingController();
  final _maxPeriodController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  final _sharePriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingSetting != null) {
      final setting = widget.existingSetting!;
      _nameController.text = setting.name;
      _interestRateController.text = setting.interestRate.toString();
      _maxPeriodController.text = setting.maxPeriodMonths.toString();
      _shareSaving = setting.shareSaving;

      if (setting.multiplier != null) {
        _isMultiplier = true;
        _multiplierController.text = setting.multiplier.toString();
      } else if (setting.percentage != null) {
        _isMultiplier = false;
        _percentageController.text = setting.percentage.toString();
      }

      if (setting.minAmounts != null || setting.maxAmounts != null) {
        _hasMinMaxAmounts = true;
        _minAmountController.text = setting.minAmounts?.toString() ?? '';
        _maxAmountController.text = setting.maxAmounts?.toString() ?? '';
      }

      if (setting.sharePrice != null) {
        _sharePriceController.text = setting.sharePrice.toString();
      }
    }
  }

  Future<void> _saveLoanSetting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final loanSetting = LoanSetting(
        id: widget.existingSetting?.id,
        name: _nameController.text,
        minAmounts: _hasMinMaxAmounts && _minAmountController.text.isNotEmpty
            ? double.parse(_minAmountController.text)
            : null,
        maxAmounts: _hasMinMaxAmounts && _maxAmountController.text.isNotEmpty
            ? double.parse(_maxAmountController.text)
            : null,
        shareSaving: _shareSaving,
        sharePrice:
            _shareSaving == 'SHARE' && _sharePriceController.text.isNotEmpty
                ? double.parse(_sharePriceController.text)
                : null,
        jumuiyaId: widget.jumuiyaId,
        interestRate: double.parse(_interestRateController.text),
        multiplier:
            _isMultiplier ? double.parse(_multiplierController.text) : null,
        percentage:
            !_isMultiplier ? double.parse(_percentageController.text) : null,
        maxPeriodMonths: int.parse(_maxPeriodController.text),
      );

      final result = await _loanSettingService.createLoanSetting(loanSetting);

      if (result['status'] == '200' || result['status'] == 200) {
        _showSnackBar('Mipangilio ya mkopo imehifadhiwa kikamilifu!');
        widget.onSaved();
      } else {
        _showSnackBar(result['message'] ?? 'Imeshindwa kuhifadhi',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Hitilafu: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildNameField(),
                    const SizedBox(height: 20),
                    _buildMinMaxSwitch(),
                    if (_hasMinMaxAmounts) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildMinAmountField()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMaxAmountField()),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildShareSavingSelector(),
                    if (_shareSaving == 'SHARE') ...[
                      const SizedBox(height: 16),
                      _buildSharePriceField(),
                    ],
                    const SizedBox(height: 20),
                    _buildLoanTypeSelector(),
                    const SizedBox(height: 20),
                    _buildInterestRateField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_isMultiplier)
                          Expanded(child: _buildMultiplierField()),
                        if (!_isMultiplier)
                          Expanded(child: _buildPercentageField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMaxPeriodField()),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [mainFontColor, mainFontColor.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.existingSetting != null
                ? Icons.edit_rounded
                : Icons.add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.existingSetting != null ? 'Hariri Mpango' : 'Mpango Mpya',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Jina la Mpango',
        hintText: 'Mfano: Mkopo wa Biashara',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tafadhali ingiza jina la mpango';
        }
        return null;
      },
    );
  }

  Widget _buildMinMaxSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: const Text(
          'Weka Kikomo cha Kiasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Kikomo cha chini na juu cha mkopo',
          style: TextStyle(fontSize: 13),
        ),
        value: _hasMinMaxAmounts,
        onChanged: (value) => setState(() => _hasMinMaxAmounts = value),
        activeColor: mainFontColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildShareSavingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Msingi wa Mkopo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child:
                  _buildRadioOption('SAVING', 'Akiba', Icons.savings_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRadioOption('SHARE', 'Hisa', Icons.share_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioOption(String value, String label, IconData icon) {
    final isSelected = _shareSaving == value;
    return InkWell(
      onTap: () => setState(() => _shareSaving = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [mainFontColor, mainFontColor.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? mainFontColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mainFontColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aina ya Kikomo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(true, 'Mzidishaji', Icons.close_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(false, 'Asilimia', Icons.percent_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(bool isMultiplier, String label, IconData icon) {
    final isSelected = _isMultiplier == isMultiplier;
    return InkWell(
      onTap: () => setState(() => _isMultiplier = isMultiplier),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [mainFontColor, mainFontColor.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? mainFontColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mainFontColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
      ],
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mainFontColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: mainFontColor, size: 20),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mainFontColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildInterestRateField() {
    return _buildTextField(
      controller: _interestRateController,
      label: 'Riba (%)',
      hint: 'Ingiza kiwango cha riba',
      icon: Icons.trending_up,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Tafadhali ingiza riba' : null,
    );
  }

  Widget _buildMultiplierField() {
    return _buildTextField(
      controller: _multiplierController,
      label: 'Mzidishaji',
      hint: 'Mfano: 4',
      icon: Icons.close,
      validator: (value) => _isMultiplier && (value?.isEmpty ?? true)
          ? 'Ingiza mzidishaji'
          : null,
    );
  }

  Widget _buildPercentageField() {
    return _buildTextField(
      controller: _percentageController,
      label: 'Asilimia (%)',
      hint: 'Mfano: 80',
      icon: Icons.percent,
      validator: (value) =>
          !_isMultiplier && (value?.isEmpty ?? true) ? 'Ingiza asilimia' : null,
    );
  }

  Widget _buildMaxPeriodField() {
    return _buildTextField(
      controller: _maxPeriodController,
      label: 'Kipindi cha Juu (Miezi)',
      hint: 'Ingiza idadi ya miezi',
      icon: Icons.calendar_month,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Tafadhali ingiza kipindi' : null,
    );
  }

  Widget _buildMinAmountField() {
    return _buildTextField(
      controller: _minAmountController,
      label: 'Kiasi cha Chini',
      hint: 'Kiasi kidogo kinachoweza kuazimwa',
      icon: Icons.arrow_downward,
      validator: null,
    );
  }

  Widget _buildMaxAmountField() {
    return _buildTextField(
      controller: _maxAmountController,
      label: 'Kiasi cha Juu',
      hint: 'Kiasi kikubwa kinachoweza kuazimwa',
      icon: Icons.arrow_upward,
      validator: null,
    );
  }

  Widget _buildSharePriceField() {
    return _buildTextField(
      controller: _sharePriceController,
      label: 'Bei ya Hisa',
      hint: 'Ingiza bei ya hisa moja',
      icon: Icons.price_change,
      validator: (value) => _shareSaving == 'SHARE' && (value?.isEmpty ?? true)
          ? 'Ingiza bei ya hisa'
          : null,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [mainFontColor, mainFontColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: mainFontColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveLoanSetting,
        icon: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save_rounded, size: 22),
        label: Text(
          _isLoading ? 'Inahifadhi...' : 'Hifadhi Mipangilio',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _interestRateController.dispose();
    _multiplierController.dispose();
    _percentageController.dispose();
    _maxPeriodController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _sharePriceController.dispose();
    super.dispose();
  }
}
