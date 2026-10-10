enum PaymentService { mobile, internet, utilities }

extension PaymentServiceX on PaymentService {
  String get title => switch (this) {
        PaymentService.mobile => 'Mobil aloqa',
        PaymentService.internet => 'Internet',
        PaymentService.utilities => 'Kommunal xizmatlar',
      };

  String get accountLabel => switch (this) {
        PaymentService.mobile => 'Telefon raqami',
        PaymentService.internet => 'Abonent ID',
        PaymentService.utilities => 'Shaxsiy hisob',
      };
}
