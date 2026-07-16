import '../../domain/entities/scientific_reference.dart';

class ScientificReferencesRegistry {
  static List<ScientificReference> getReferencesForSubstance(
      String substance, String languageCode) {
    final normalized = substance.toLowerCase();
    final isAr = languageCode == 'ar';

    if (normalized.contains('cocaine') || normalized.contains('كوكايين')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr
              ? 'كوكايين - PubChem CID 446220'
              : 'Cocaine - PubChem CID 446220',
          description: isAr
              ? 'الملف الكيميائي والسمومي الكامل للكوكايين من قاعدة البيانات الوطنية للطب (NIH).'
              : 'Complete chemical and toxicological profile of Cocaine from the National Library of Medicine (NIH).',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/Cocaine',
        ),
        ScientificReference(
          sourceName: 'DrugBank',
          title: isAr
              ? 'كوكايين - DrugBank DB00907'
              : 'Cocaine - DrugBank DB00907',
          description: isAr
              ? 'معلومات مفصلة حول الحرائك الدوائية والمسارات الأيضية والمستهدفات الحيوية للكوكايين.'
              : 'Detailed pharmacology, pharmacokinetic pathways, and biological targets of Cocaine.',
          url: 'https://go.drugbank.com/drugs/DB00907',
        ),
      ];
    } else if (normalized.contains('mdma') ||
        normalized.contains('ecstasy') ||
        normalized.contains('إكستاسي')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr ? 'MDMA - PubChem CID 1615' : 'MDMA - PubChem CID 1615',
          description: isAr
              ? 'الخصائص الفيزيائية والكيميائية والآثار الجانبية لمركب 3,4-ميثيلين ديوكسي ميثامفيتامين.'
              : 'Physical, chemical properties, and hazard profiles of 3,4-methylenedioxymethamphetamine.',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/1615',
        ),
        ScientificReference(
          sourceName: 'NIST Chemistry WebBook',
          title: isAr
              ? 'بيانات الطيف لـ MDMA - NIST'
              : 'MDMA Spectral Data - NIST',
          description: isAr
              ? 'بيانات التحليل الطيفي بالأشعة تحت الحمراء وطيف الكتلة من المعهد الوطني للمعايير والتقنية.'
              : 'Infrared and Mass spectrometry database records from the National Institute of Standards and Technology.',
          url: 'https://webbook.nist.gov/cgi/cbook.cgi?ID=C42579343',
        ),
      ];
    } else if (normalized.contains('heroin') ||
        normalized.contains('هيروين') ||
        normalized.contains('morphine') ||
        normalized.contains('مورفين') ||
        normalized.contains('opium') ||
        normalized.contains('أفيون') ||
        normalized.contains('opiate') ||
        normalized.contains('أفيونات')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr
              ? 'هيروين - PubChem CID 5462328'
              : 'Heroin - PubChem CID 5462328',
          description: isAr
              ? 'الملف الكيميائي والسمومي لثنائي أسيتيل مورفين من المكتبة الوطنية للطب.'
              : 'Chemical, safety, and toxicology data of Diacetylmorphine from the National Library of Medicine.',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/Diacetylmorphine',
        ),
        ScientificReference(
          sourceName: 'WHO',
          title: isAr
              ? 'تقرير منظمة الصحة العالمية بشأن المواد الأفيونية'
              : 'WHO Opiates Information',
          description: isAr
              ? 'إرشادات منظمة الصحة العالمية بشأن الوفيات الناجمة عن جرعات الأفيون الزائدة وإدارة الاعتماد.'
              : 'World Health Organization guidelines on opiate overdose prevention and dependence management.',
          url: 'https://www.who.int/news-room/fact-sheets/detail/opioids',
        ),
      ];
    } else if (normalized.contains('lsd') || normalized.contains('أل أس دي')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr ? 'LSD - PubChem CID 5768' : 'LSD - PubChem CID 5768',
          description: isAr
              ? 'الملف التعريفي العلمي لثنائي إيثيل أميد حمض الليسرجيك، يشمل البنية ثلاثية الأبعاد والسمية.'
              : 'Scientific profile of Lysergic Acid Diethylamide, containing 3D structure and toxicity records.',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/5768',
        ),
        ScientificReference(
          sourceName: 'DrugBank',
          title: isAr ? 'LSD - DrugBank DB04829' : 'LSD - DrugBank DB04829',
          description: isAr
              ? 'دراسة دوائية لمستهدفات مستقبلات السيروتونين والخصائص الكيميائية والفيزيائية للـ LSD.'
              : 'Pharmacological study of serotonin receptor targets, chemical properties, and clinical trial context for LSD.',
          url: 'https://go.drugbank.com/drugs/DB04829',
        ),
      ];
    } else if (normalized.contains('amphetamine') ||
        normalized.contains('أمفيتامين') ||
        normalized.contains('methamphetamine') ||
        normalized.contains('ميثامفيتامين') ||
        normalized.contains('stimulant') ||
        normalized.contains('منشطات')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr
              ? 'أمفيتامين - PubChem CID 3007'
              : 'Amphetamine - PubChem CID 3007',
          description: isAr
              ? 'البيانات الكيميائية والفيزيائية والسمية الكاملة للأمفيتامين من المكتبة الوطنية للطب.'
              : 'Comprehensive chemical, physical, and toxicological data of Amphetamine from NLM.',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/3007',
        ),
        ScientificReference(
          sourceName: 'NIH / NIDA',
          title: isAr
              ? 'المعهد الوطني لمكافحة إساءة استخدام العقاقير (NIDA)'
              : 'NIH / NIDA Methamphetamine Report',
          description: isAr
              ? 'تقرير بحثي مفصل من المعاهد الوطنية للصحة حول الميثامفيتامين وتأثيراته العصبية.'
              : 'Detailed research report from NIH/NIDA on methamphetamine, its mechanism, and neurological impacts.',
          url:
              'https://nida.nih.gov/publications/research-reports/methamphetamine',
        ),
      ];
    } else if (normalized.contains('psilocybin') ||
        normalized.contains('سيلوسيبين')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr
              ? 'سيلوسيبين - PubChem CID 4980'
              : 'Psilocybin - PubChem CID 4980',
          description: isAr
              ? 'الملف الكيميائي والسمومي للسيلوسيبين، وهو المركب ذو التأثير النفسي النشط في الفطر السحري.'
              : 'Chemical and toxicological profile of Psilocybin, the psychoactive compound found in magic mushrooms.',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/4980',
        ),
        ScientificReference(
          sourceName: 'DrugBank',
          title: isAr
              ? 'سيلوسيبين - DrugBank DB14746'
              : 'Psilocybin - DrugBank DB14746',
          description: isAr
              ? 'معلومات مفصلة حول استخدامات السيلوسيبين الطبية التجريبية وآلية عمله الدوائية.'
              : 'Detailed analysis of Psilocybin clinical trials, pharmacological mechanism, and serotonin receptor binding.',
          url: 'https://go.drugbank.com/drugs/DB14746',
        ),
      ];
    } else if (normalized.contains('cannabis') ||
        normalized.contains('thc') ||
        normalized.contains('cannabinoid') ||
        normalized.contains('حشيش') ||
        normalized.contains('قنب') ||
        normalized.contains('ماريجوانا')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr
              ? 'تتراهيدروكانابينول - PubChem CID 16078'
              : 'Tetrahydrocannabinol - PubChem CID 16078',
          description: isAr
              ? 'البيانات الكيميائية والسريرية والسمية الكاملة لمركب الدلتا-9-تتراهيدروكانابينول (THC).'
              : 'Full chemical, clinical, and safety profile of Delta-9-Tetrahydrocannabinol (THC).',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/16078',
        ),
        ScientificReference(
          sourceName: 'WHO',
          title: isAr
              ? 'تقرير منظمة الصحة العالمية حول الحشيش وقنب الهند'
              : 'WHO Cannabis Report',
          description: isAr
              ? 'التقييمات الصحية والسياسات العلمية المعتمدة من منظمة الصحة العالمية بشأن نبات القنب ومشتقاته.'
              : 'World Health Organization health assessments and scientific policies regarding cannabis and its derivatives.',
          url:
              'https://www.who.int/teams/mental-health-and-substance-use/alcohol-drugs-and-addictive-behaviours/drugs/cannabis',
        ),
      ];
    } else if (normalized.contains('ketamine') ||
        normalized.contains('كيتامين')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr
              ? 'كيتامين - PubChem CID 3821'
              : 'Ketamine - PubChem CID 3821',
          description: isAr
              ? 'معلومات شاملة حول كيتامين هيدروكلوريد، الخصائص الكيميائية وتأثيرات التخدير.'
              : 'Comprehensive compound information on Ketamine Hydrochloride, physical attributes, and anesthetic properties.',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/3821',
        ),
        ScientificReference(
          sourceName: 'DrugBank',
          title: isAr
              ? 'كيتامين - DrugBank DB01221'
              : 'Ketamine - DrugBank DB01221',
          description: isAr
              ? 'معلومات الآلية الدوائية للكيتامين كعامل مضاد لمستقبلات NMDA والاستخدامات العلاجية.'
              : 'Pharmacokinetics and action mechanism of Ketamine as an NMDA receptor antagonist.',
          url: 'https://go.drugbank.com/drugs/DB01221',
        ),
      ];
    } else if (normalized.contains('dmt') || normalized.contains('دي أم تي')) {
      return [
        ScientificReference(
          sourceName: 'PubChem',
          title: isAr
              ? 'N,N-ثنائي ميثيل تريبتامين - PubChem CID 6089'
              : 'N,N-Dimethyltryptamine - PubChem CID 6089',
          description: isAr
              ? 'التركيبة الكيميائية وتأثيرات الهلوسة والسمية ومصادر مركب DMT الطبيعية.'
              : 'Chemical formula, hallucinogenic effects, safety parameters, and natural sources of N,N-Dimethyltryptamine.',
          url: 'https://pubchem.ncbi.nlm.nih.gov/compound/6089',
        ),
      ];
    }

    return [];
  }
}
