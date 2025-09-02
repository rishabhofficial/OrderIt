// Script to help fix null safety issues in the OrderIt project
// Run this script to get guidance on fixing remaining issues

void main() {
  print('''
=== NULL SAFETY FIXING GUIDE ===

The following files need to be updated to fix null safety issues:

1. lib/ui/allProduct.dart - Multiple issues:
   - Fix ProductData instantiation with required parameters
   - Fix Order instantiation with required parameters
   - Fix null access issues with selectedProductList

2. lib/ui/product.dart - Multiple issues:
   - Fix ProductData instantiation with required parameters
   - Fix null access issues with globalFixedSalesData
   - Fix FilePickerResult null handling

3. lib/ui/company.dart - Multiple issues:
   - Fix StreamBuilder typing
   - Fix null access issues with snapshot.data

4. lib/ui/letterheadList.dart - Multiple issues:
   - Fix FormState null access
   - Fix DateTime null handling
   - Fix required parameters in constructors

5. lib/ui/party.dart - Multiple issues:
   - Fix StreamBuilder typing
   - Fix null access issues

6. lib/ui/partyReport.dart - Multiple issues:
   - Fix List null access
   - Fix DateTime null handling

7. lib/ui/prodSearch.dart - Multiple issues:
   - Fix required parameters in constructors

8. lib/ui/sentProduct.dart - Multiple issues:
   - Fix StreamBuilder typing

9. lib/ui/transactionList.dart - Multiple issues:
   - Fix StreamBuilder typing
   - Fix null access issues

=== QUICK FIX APPROACH ===

1. For ProductData instantiation, use this pattern:
   ProductData(
     icode: data['icode']?.toString() ?? '',
     name: data['name']?.toString() ?? '',
     pack: data['pack']?.toString() ?? '',
     qty: data['qty']?.toString() ?? '0',
     division: data['division']?.toString() ?? '',
     expiryDate: data['expiryDate']?.toString() ?? '',
     deal1: int.tryParse(data['deal1']?.toString() ?? '0') ?? 0,
     deal2: int.tryParse(data['deal2']?.toString() ?? '0') ?? 0,
     mrp: double.tryParse(data['mrp']?.toString() ?? '0.0') ?? 0.0,
     batchNumber: data['batchNumber']?.toString() ?? '',
     compCode: data['compCode']?.toString() ?? '',
     amount: double.tryParse(data['amount']?.toString() ?? '0.0') ?? 0.0,
   )

2. For StreamBuilder, use this pattern:
   StreamBuilder<QuerySnapshot>(
     stream: FirebaseFirestore.instance.collection("Collection").snapshots(),
     builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
       if (!snapshot.hasData) {
         return Center(child: CircularProgressIndicator());
       }
       return ListView.builder(
         itemCount: snapshot.data!.docs.length,
         itemBuilder: (context, index) {
           DocumentSnapshot doc = snapshot.data!.docs[index];
           // Use doc.data() safely
         },
       );
     },
   )

3. For null access issues, use null-aware operators:
   - Use ?. for safe property access
   - Use ?? for default values
   - Use !. when you're certain the value is not null

4. For required parameters, add 'required' keyword:
   Constructor({
     required this.param1,
     required this.param2,
   });

5. For nullable variables, provide default values:
   String name = '';
   int count = 0;
   double amount = 0.0;
   bool isActive = false;

=== ALTERNATIVE APPROACH ===

If the issues are too extensive, consider:

1. Temporarily downgrade SDK version in pubspec.yaml:
   environment:
     sdk: ">=2.2.2 <3.0.0"

2. Use Flutter's migration tool:
   dart migrate --apply

3. Fix files one by one, starting with the most critical ones.

=== PRIORITY ORDER ===

1. Fix model.dart (already done)
2. Fix globals.dart (already done)
3. Fix allProduct.dart
4. Fix product.dart
5. Fix company.dart
6. Fix remaining UI files

This will ensure the core functionality works first, then the UI components.
''');
}
