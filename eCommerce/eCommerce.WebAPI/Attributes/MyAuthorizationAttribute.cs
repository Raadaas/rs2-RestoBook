using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace eCommerce.WebAPI.Attributes;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class MyAuthorizationAttribute : Attribute, IAuthorizationFilter
{
    private readonly bool _requireAdmin;
    private readonly bool _requireClient;

    /// <summary>
    /// Admin-only: requireAdmin: true, requireClient: false.
    /// Client-only: requireAdmin: false, requireClient: true.
    /// Both allowed: omit or use both false.
    /// </summary>
    public MyAuthorizationAttribute(bool requireAdmin = false, bool requireClient = false)
    {
        _requireAdmin = requireAdmin;
        _requireClient = requireClient;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;

        if (!user.Identity?.IsAuthenticated ?? true)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        if (_requireAdmin && !user.IsInRole("Admin"))
        {
            context.Result = new ObjectResult(new { message = "Admin role required" }) { StatusCode = 403 };
            return;
        }

        if (_requireClient && !user.IsInRole("Client"))
        {
            context.Result = new ObjectResult(new { message = "Client role required" }) { StatusCode = 403 };
            return;
        }
    }
}
