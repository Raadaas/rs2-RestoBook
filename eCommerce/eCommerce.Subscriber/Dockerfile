FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# Copy all project files
COPY . .

# Publish the Subscriber project
RUN dotnet publish eCommerce.Subscriber/eCommerce.Subscriber.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/runtime:7.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "eCommerce.Subscriber.dll"]

