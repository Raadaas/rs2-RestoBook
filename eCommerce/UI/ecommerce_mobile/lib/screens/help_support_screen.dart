import 'package:flutter/material.dart';
import 'package:ecommerce_mobile/app_styles.dart';

const Color _brown = Color(0xFF8B7355);
const Color _brownLight = Color(0xFFB39B7A);

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<({String question, String answer})> _faqs = [
    (
      question: 'How do I cancel a reservation?',
      answer:
          'Go to Bookings tab, select your reservation and tap Cancel. You can cancel up to 2 hours before your booking time.',
    ),
    (
      question: 'How can I earn loyalty points?',
      answer:
          'Points are earned automatically for every completed reservation and for purchases at participating restaurants.',
    ),
    (
      question: 'Can I book for large groups?',
      answer:
          'Yes, for groups over 10 please contact the restaurant directly to arrange your booking.',
    ),
    (
      question: "What if I'm running late?",
      answer:
          'We recommend calling the restaurant. Most restaurants will hold your table for 15–20 minutes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Help & Support', style: kScreenTitleStyle),
            ),
            kScreenTitleUnderline(),
            _buildContactSection(context),
            const SizedBox(height: 32),
            _buildFaqSection(context),
            const SizedBox(height: 32),
            _buildMoreResourcesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Container(width: 3, height: 20, decoration: BoxDecoration(color: _brown, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text(
                'Contact us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _brownLight.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 20, color: _brown),
                  const SizedBox(width: 12),
                  const Text(
                    '+385 91 123 4567',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 20, color: _brown),
                  const SizedBox(width: 12),
                  const Text(
                    'support@restobook.com',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Container(width: 3, height: 20, decoration: BoxDecoration(color: _brown, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _brownLight.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              return _FaqTileFull(
                question: faq.question,
                answer: faq.answer,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoreResourcesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Container(width: 3, height: 20, decoration: BoxDecoration(color: _brown, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text(
                'More Resources',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _brownLight.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Icon(Icons.open_in_new, color: _brown, size: 24),
                title: const Text(
                  'User Guide & Tutorials',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: _brownLight),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserGuideScreen(),
                    ),
                  );
                },
              ),
              Divider(height: 1, color: Colors.grey[200]),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Icon(Icons.help_outline, color: _brown, size: 24),
                title: const Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: _brownLight),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

}

class _FaqTileFull extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTileFull({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'User Guide & Tutorials',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Container(height: 3, width: 48, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: _brownLight, borderRadius: BorderRadius.circular(2))),
            _sectionTitle('Getting started'),
            _paragraph(
              'RestoBook lets you discover restaurants, make reservations, and earn loyalty points. After signing in, use the bottom navigation to switch between Home, Search, Bookings, and Profile.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('Making a reservation'),
            _paragraph(
              'Search for a restaurant or browse the home screen. Open a restaurant, choose date and time, and tap Book. You can manage or cancel your booking from the Bookings tab up to 2 hours before the reserved time.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('Loyalty & rewards'),
            _paragraph(
              'Earn points on every completed reservation and at participating venues. Check your balance and rewards in Profile. Redeem points for discounts or special offers at partner restaurants.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('Favorites & reviews'),
            _paragraph(
              'Save places you like with the heart icon and leave a rating and comment after your visit. Your favorites and reviews are available from your Profile.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(color: _brown, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[800],
        height: 1.5,
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Container(height: 3, width: 48, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: _brownLight, borderRadius: BorderRadius.circular(2))),
            _sectionTitle('1. Acceptance of terms'),
            _paragraph(
              'By using the RestoBook app and services you agree to these terms. If you do not agree, please do not use the service.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('2. Use of the service'),
            _paragraph(
              'You may use the app to search for restaurants, make and manage reservations, and participate in loyalty programs. You must provide accurate information and use the service only for lawful purposes. You are responsible for keeping your account credentials secure.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('3. Reservations and cancellations'),
            _paragraph(
              'Reservations are subject to restaurant availability and policies. Cancellation rules (e.g. minimum notice) are shown at the time of booking. Repeated no-shows may result in restrictions on your account.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('4. Changes and availability'),
            _paragraph(
              'We strive to keep information up to date but do not guarantee accuracy of menus, opening hours, or availability. The restaurant is responsible for the actual service provided.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('5. Contact'),
            _paragraph(
              'For questions about these terms or the service, please use the Help & Support section in the app or contact our support team.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(color: _brown, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[800],
        height: 1.5,
      ),
    );
  }
}
