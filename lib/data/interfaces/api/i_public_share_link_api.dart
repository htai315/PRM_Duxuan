import 'package:du_xuan/data/dtos/share/create_public_share_link_request_dto.dart';
import 'package:du_xuan/data/dtos/share/public_share_link_dto.dart';
import 'package:du_xuan/data/dtos/share/update_public_share_link_request_dto.dart';

abstract class IPublicShareLinkApi {
  Future<PublicShareLinkDto?> getById(int id);
  Future<PublicShareLinkDto?> getByPlanId(int planId);
  Future<PublicShareLinkDto?> getByShareId(String shareId);
  Future<int> create(CreatePublicShareLinkRequestDto req);
  Future<void> update(UpdatePublicShareLinkRequestDto req);
  Future<void> deleteByPlanId(int planId);
}
