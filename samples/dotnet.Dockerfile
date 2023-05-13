FROM mcr.microsoft.com/dotnet/aspnet:7.0-alpine
ARG DLL_NAME=base
ENV APP_EXEC=$DLL_NAME
WORKDIR /app
EXPOSE 80
EXPOSE 443
ENV ASPNETCORE_URLS=http://+:$BUILD_PORT
ENV ASPNETCORE_ENVIRONMENT=development
RUN apk add --no-cache ca-certificates bash 
COPY . .
ENTRYPOINT dotnet $APP_EXEC