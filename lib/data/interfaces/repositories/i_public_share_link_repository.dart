import 'package:du_xuan/domain/entities/public_share_link.dart';

abstract class IPublicShareLinkRepository {
  Future<PublicShareLink?> getByPlanId(int planId);
  Future<PublicShareLink?> getByShareId(String shareId);
  Future<PublicShareLink> create(PublicShareLink link);
  Future<void> update(PublicShareLink link);
  Future<void> deleteByPlanId(int planId);
}
