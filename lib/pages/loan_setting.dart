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
  final _formKey = GlobalKey<FormState>();
  final _loanSettingService = LoanSettingService();

  bool _isLoading = false;
  bool _isMultiplier = true; // true for multiplier, false for percentage
  LoanSetting? _existingSetting;

  final _interestRateController = TextEditingController();
  final _multiplierController = TextEditingController();
  final _percentageController = TextEditingController();
  final _maxPeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingSetting();
  }

  Future<void> _loadExistingSetting() async {
    setState(() => _isLoading = true);
    try {
      final setting =
          await _loanSettingService.getLoanSettingByJumuiyaId(widget.jumuiyaId);
      if (setting != null) {
        setState(() {
          _existingSetting = setting;
          _interestRateController.text = setting.interestRate.toString();
          _maxPeriodController.text = setting.maxPeriodMonths.toString();

          if (setting.multiplier != null) {
            _isMultiplier = true;
            _multiplierController.text = setting.multiplier.toString();
          } else if (setting.percentage != null) {
            _isMultiplier = false;
            _percentageController.text = setting.percentage.toString();
          }
        });
      }
    } catch (e) {
      _showSnackBar('Hitilafu: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLoanSetting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final loanSetting = LoanSetting(
        id: _existingSetting?.id,
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
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainFontColor,
        foregroundColor: Colors.white,
        title: const Text('Mipangilio ya Mkopo'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExistingSetting,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildLoanTypeSelector(),
                    const SizedBox(height: 20),
                    _buildInterestRateField(),
                    const SizedBox(height: 16),
                    if (_isMultiplier) _buildMultiplierField(),
                    if (!_isMultiplier) _buildPercentageField(),
                    const SizedBox(height: 16),
                    _buildMaxPeriodField(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tengeneza Mipangilio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Weka vigezo vya mikopo kwa jumuiya',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aina ya Mkopo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    title: 'Mzidishaji',
                    subtitle: 'Kikomo cha mkopo ni mzidishaji wa hisa',
                    icon: Icons.calculate,
                    isSelected: _isMultiplier,
                    onTap: () => setState(() => _isMultiplier = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionCard(
                    title: 'Asilimia',
                    subtitle: 'Kikomo cha mkopo ni asilimia ya hisa',
                    icon: Icons.percent,
                    isSelected: !_isMultiplier,
                    onTap: () => setState(() => _isMultiplier = false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tafadhali ingiza riba';
        }
        if (double.tryParse(value) == null) {
          return 'Ingiza nambari halali';
        }
        return null;
      },
    );
  }

  Widget _buildMultiplierField() {
    return _buildTextField(
      controller: _multiplierController,
      label: 'Mzidishaji',
      hint: 'Mfano: 4 (mkopo ni mara 4 ya hisa)',
      icon: Icons.close,
      validator: (value) {
        if (_isMultiplier && (value == null || value.isEmpty)) {
          return 'Tafadhali ingiza mzidishaji';
        }
        if (_isMultiplier && double.tryParse(value!) == null) {
          return 'Ingiza nambari halali';
        }
        return null;
      },
    );
  }

  Widget _buildPercentageField() {
    return _buildTextField(
      controller: _percentageController,
      label: 'Asilimia (%)',
      hint: 'Mfano: 80 (mkopo ni 80% ya hisa)',
      icon: Icons.percent,
      validator: (value) {
        if (!_isMultiplier && (value == null || value.isEmpty)) {
          return 'Tafadhali ingiza asilimia';
        }
        if (!_isMultiplier && double.tryParse(value!) == null) {
          return 'Ingiza nambari halali';
        }
        return null;
      },
    );
  }

  Widget _buildMaxPeriodField() {
    return _buildTextField(
      controller: _maxPeriodController,
      label: 'Kipindi cha Juu (Miezi)',
      hint: 'Ingiza idadi ya miezi',
      icon: Icons.calendar_month,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tafadhali ingiza kipindi';
        }
        if (int.tryParse(value) == null) {
          return 'Ingiza nambari halali';
        }
        return null;
      },
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
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.save),
      label: Text(
        _isLoading ? 'Inahifadhi...' : 'Hifadhi Mipangilio',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interestRateController.dispose();
    _multiplierController.dispose();
    _percentageController.dispose();
    _maxPeriodController.dispose();
    super.dispose();
  }
}
