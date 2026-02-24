using eCommerce.Model.Responses;

namespace eCommerce.WebAPI.Services;

public interface IJwtTokenService
{
    string GenerateToken(UserResponse user);
}
