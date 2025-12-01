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
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Mipangilio ya Mikopo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllSettings,
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
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        label: const Text(
          'Ongeza Mpango',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: mainFontColor,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_suggest, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Hakuna mipangilio ya mikopo',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Bonyeza kitufe cha chini kuongeza',
            style: TextStyle(color: Colors.grey[500]),
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
        return _buildSettingCard(setting);
      },
    );
  }

  Widget _buildSettingCard(LoanSetting setting) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAddEditBottomSheet(setting: setting),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      setting.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.edit, color: mainFontColor),
                ],
              ),
              const Divider(height: 16),
              _buildInfoRow(
                  Icons.account_balance, 'Msingi', setting.shareSaving),
              _buildInfoRow(
                  Icons.trending_up, 'Riba', '${setting.interestRate}%'),
              if (setting.multiplier != null)
                _buildInfoRow(
                    Icons.close, 'Mzidishaji', 'x${setting.multiplier}'),
              if (setting.percentage != null)
                _buildInfoRow(
                    Icons.percent, 'Asilimia', '${setting.percentage}%'),
              _buildInfoRow(Icons.calendar_month, 'Kipindi',
                  '${setting.maxPeriodMonths} miezi'),
              if (setting.minAmounts != null || setting.maxAmounts != null)
                _buildInfoRow(
                  Icons.money,
                  'Kikomo',
                  '${setting.minAmounts ?? 0} - ${setting.maxAmounts ?? 'Hakuna'}',
                ),
              if (setting.sharePrice != null)
                _buildInfoRow(Icons.price_change, 'Bei ya Hisa',
                    'Tsh ${setting.sharePrice}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildMinMaxSwitch(),
              if (_hasMinMaxAmounts) ...[
                const SizedBox(height: 16),
                _buildMinAmountField(),
                const SizedBox(height: 16),
                _buildMaxAmountField(),
              ],
              const SizedBox(height: 16),
              _buildShareSavingSelector(),
              if (_shareSaving == 'SHARE') ...[
                const SizedBox(height: 16),
                _buildSharePriceField(),
              ],
              const SizedBox(height: 16),
              _buildLoanTypeSelector(),
              const SizedBox(height: 16),
              _buildInterestRateField(),
              const SizedBox(height: 16),
              if (_isMultiplier) _buildMultiplierField(),
              if (!_isMultiplier) _buildPercentageField(),
              const SizedBox(height: 16),
              _buildMaxPeriodField(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.existingSetting != null ? 'Hariri Mpango' : 'Mpango Mpya',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
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
    return SwitchListTile(
      title: const Text('Weka Kikomo cha Kiasi'),
      subtitle: const Text('Kikomo cha chini na juu cha mkopo'),
      value: _hasMinMaxAmounts,
      onChanged: (value) => setState(() => _hasMinMaxAmounts = value),
      activeColor: mainFontColor,
    );
  }

  Widget _buildShareSavingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Msingi wa Mkopo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRadioOption('SAVING', 'Akiba', Icons.savings),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRadioOption('SHARE', 'Hisa', Icons.share),
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? mainFontColor.withOpacity(0.1) : Colors.grey[100],
          border:
              Border.all(color: isSelected ? mainFontColor : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? mainFontColor : Colors.grey),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected ? mainFontColor : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aina ya Kikomo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(true, 'Mzidishaji', Icons.calculate),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(false, 'Asilimia', Icons.percent),
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? mainFontColor.withOpacity(0.1) : Colors.grey[100],
          border:
              Border.all(color: isSelected ? mainFontColor : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? mainFontColor : Colors.grey),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected ? mainFontColor : Colors.grey[700])),
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _saveLoanSetting,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
          : const Icon(Icons.save),
      label: Text(_isLoading ? 'Inahifadhi...' : 'Hifadhi Mipangilio'),
      style: ElevatedButton.styleFrom(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
