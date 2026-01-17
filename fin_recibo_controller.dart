import 'package:flutter/material.dart';

import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../amb/amb_lib_utils.dart';
import '../amb/amb_extenso_valores.dart';
import '../services/fin/fin_recibo_pdf.dart';



class FinReciboController extends ChangeNotifier {

  static Widget _itemTipoPessoa(IconData icone, String label) {
    return Row(
      children: [
        Icon(icone),
        const SizedBox(width: 5.0,),
        Text(label),
      ],
    );
  }

  final List<DropdownMenuItem<String>> _lItensTipoPessoa = [
    DropdownMenuItem(value: '1', child: _itemTipoPessoa(Icons.apartment, 'Pessoa Jurídica')),
    DropdownMenuItem(value: '2', child: _itemTipoPessoa(Icons.person, 'Pessoa Física')),
    DropdownMenuItem(value: '0', child: _itemTipoPessoa(Icons.help_outline, 'Não Especificada')),
  ];



  String _tipoPessoaPagador = '2';
  String _labelDocPessoaPagador = 'CPF';

  String _tipoPessoaRecebedor = '2';
  String _labelDocPessoaRecebedor = 'CPF';

  final TextEditingController _valorDigitado = TextEditingController(text: '0,00');
  String _valorExtenso = '';



  List<DropdownMenuItem<String>> get lItensTipoPessoa =>_lItensTipoPessoa;
  
  String get tipoPessoaPagador => _tipoPessoaPagador;
  String get labelDocPessoaPagador => _labelDocPessoaPagador;

  String get tipoPessoaRecebedor => _tipoPessoaRecebedor;
  String get labelDocPessoaRecebedor => _labelDocPessoaRecebedor;

  TextEditingController get valorDigitado {
    return _valorDigitado;
  }

  String get valorExtenso {
    return _valorExtenso;
  }



  void setTipoPessoaPagador(String? value) {
    if (value == null) return;
    _tipoPessoaPagador = value;
    notifyListeners();
  }

  void setLabelDocPessoaPagador(String? value) {
    switch (value) {
      case '1':
        _labelDocPessoaPagador = 'CNPJ';
      case '2':
        _labelDocPessoaPagador = 'CPF';
      case '0':
        _labelDocPessoaPagador = '';
      
    }
    notifyListeners();
  }

  void setTipoPessoaRecebedor(String? value) {
    if (value == null) return;
    _tipoPessoaRecebedor = value;
    notifyListeners();
  }

  void setLabelDocPessoaRecebedor(String? value) {
    switch (value) {
      case '1':
        _labelDocPessoaRecebedor = 'CNPJ';
      case '2':
        _labelDocPessoaRecebedor = 'CPF';
      case '0':
        _labelDocPessoaRecebedor = '';
      
    }
    notifyListeners();
  }

  

  final formatadorMoeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
 
   
  void apresentarValorPorExtenso() {
    String texto = _valorDigitado.text;

    // Remove R$, espaço e tudo que não seja número
    String somenteNumeros = texto.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (somenteNumeros.isEmpty) {
      _valorDigitado.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }

    // Converte para double (usando centavos)
    double valor = double.parse(somenteNumeros) / 100;

    // Formata para padrão brasileiro
    String valorFormatado = formatadorMoeda.format(valor);

    // Atualiza campo mantendo cursor no fim
    _valorDigitado.value = TextEditingValue(
      text: valorFormatado,
      selection: TextSelection.collapsed(offset: valorFormatado.length),
    );

    // Atualiza extenso
    _valorExtenso = AmbExtensoValores().converter(valor);
    
    notifyListeners();
  }



  final cpfCnpjFormatterPagador = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  
  void setMascaraCpfCnpjPagador() {
    if(_tipoPessoaPagador == '2') {
      cpfCnpjFormatterPagador.updateMask(mask: '###.###.###-##');
    } else if(_tipoPessoaPagador == '1') {
      cpfCnpjFormatterPagador.updateMask(mask: '##.###.###/####-##');
    } else {
      cpfCnpjFormatterPagador.updateMask(mask: '#');
    }
  }


  final cpfCnpjFormatterRecebedor = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  void setMascaraCpfCnpjRecebedor() {
    if(_tipoPessoaRecebedor == '2') {
      cpfCnpjFormatterRecebedor.updateMask(mask: '###.###.###-##');
    } else if(_tipoPessoaRecebedor == '1') {
      cpfCnpjFormatterRecebedor.updateMask(mask: '##.###.###/####-##');
    } else {
      cpfCnpjFormatterRecebedor.updateMask(mask: '#');
    }
  }


  String? validarCnpjCpf({String? numDoc, required String tomadorRecebedor}) {

    String natureza = '1';

    if(tomadorRecebedor == 'T') {   // Se Tomador
      natureza = tipoPessoaPagador;

    } else {                        // Recebedor
      natureza = tipoPessoaRecebedor;
    }
   
    if(natureza == '1') {           // Pessoa Jurídica
      if(numDoc == null || numDoc.isEmpty) {
        return 'O CNPJ é Inválido';
      }  
      if(AmbLibUtils.isValidCNPJ(numDoc) == true) {
        return null;
      } else {
        return 'O CNPJ é Inválido';
      }
    
    } else if(natureza == '2') {    // Pessoa Física
      if(numDoc == null || numDoc.isEmpty) {
        return 'O CPF é Inválido';
      }  
      if(AmbLibUtils.isValidCPF(numDoc) == true) {
        return null;
      } else {
        return 'O CPF é Inválido';
      }
    
    } else {
      return null;
    }
  }

  // ------------------------------------------------------------
  // Converte "R$ 1.234,56" para 1234.56
  // ------------------------------------------------------------
  double _extrairDouble(String valor) {
    String numeros = valor.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return 0.0;

    return double.parse(numeros) / 100;
  }

  String? validaValor(String? value) {
    if(value == null || value.isEmpty || _extrairDouble(value) == 0.0) {
      return 'O valor deve ser preenchido';
    } else {
      return null;
    }   
  }


  final dataFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: { "#": RegExp(r'[0-9]') },
  );


  Future<void> gerarRecibo({
                            required String numeroRecibo,
                            required String pagador,
                            required String naturezaEntidadePagador,
                            required String documentoPagador,
                            required String descricao,
                            required DateTime data,
                            required String cidade,
                            required String uf,
                            required String recebedor,
                            required String naturezaEntidadeRecebedor,
                            required String docRecebedor,
            
    }) async {

    final pdf = FinReciboPdf.gerarReciboPdf(
           
      numeroRecibo: numeroRecibo,
      pagador: pagador,
      naturezaEntidadePagador: naturezaEntidadePagador,
      documentoPagador: documentoPagador,
      recebedor: recebedor,
      naturezaEntidadeRecebedor: naturezaEntidadeRecebedor,
      documentoRecebedor: docRecebedor,
      descricao: descricao,
      cidade: cidade,
      uf: uf,
      data: data,
      valor: _valorDigitado.text,
      valorExtenso: _valorExtenso,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
