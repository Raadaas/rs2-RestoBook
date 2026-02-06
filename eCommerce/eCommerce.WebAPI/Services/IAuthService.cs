using System.Security.Claims;

namespace eCommerce.WebAPI.Services;

public interface IAuthService
{
    AuthInfo GetAuthInfo();
}

public class AuthInfo
{
    public bool IsLoggedIn { get; set; }
    public int? UserId { get; set; }
    public string? Username { get; set; }
    public bool IsAdmin { get; set; }
    public bool IsClient { get; set; }
}
