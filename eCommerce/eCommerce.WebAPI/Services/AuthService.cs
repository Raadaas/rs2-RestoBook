using System.Security.Claims;

namespace eCommerce.WebAPI.Services;

public class AuthService : IAuthService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuthService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public AuthInfo GetAuthInfo()
    {
        var user = _httpContextAccessor.HttpContext?.User;

        if (user?.Identity?.IsAuthenticated != true)
        {
            return new AuthInfo { IsLoggedIn = false };
        }

        var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        int? userId = int.TryParse(userIdStr, out var id) ? id : null;

        return new AuthInfo
        {
            IsLoggedIn = true,
            UserId = userId,
            Username = user.FindFirst(ClaimTypes.Name)?.Value,
            IsAdmin = user.IsInRole("Admin"),
            IsClient = user.IsInRole("Client"),
        };
    }
}
