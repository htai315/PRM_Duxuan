import 'package:du_xuan/viewmodels/expense/expense_viewmodel.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/views/expense/expense_page.dart';
import 'package:flutter/material.dart';

class ExpenseTab extends StatelessWidget {
  final ExpenseViewModel expenseVM;
  final ItineraryViewModel itineraryVM;

  const ExpenseTab({
    super.key,
    required this.expenseVM,
    required this.itineraryVM,
  });

  @override
  Widget build(BuildContext context) {
    return ExpensePage(
      expenseViewModel: expenseVM,
      itineraryViewModel: itineraryVM,
      embeddedMode: true,
    );
  }
}
