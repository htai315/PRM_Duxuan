import 'package:du_xuan/data/dtos/share/create_public_share_request_dto.dart';
import 'package:du_xuan/data/dtos/share/public_share_response_dto.dart';
import 'package:du_xuan/data/dtos/share/update_public_share_request_dto.dart';
import 'package:du_xuan/domain/entities/public_share_link.dart';

abstract class IPublicShareRemoteApi {
  Future<PublicShareResponseDto> create(CreatePublicShareRequestDto req);
  Future<PublicShareResponseDto> update(
    PublicShareLink link,
    UpdatePublicShareRequestDto req,
  );
  Future<void> revoke(PublicShareLink link);
}
