java ----

FROM registry.dev.sbiepay.sbi:8443/ubi9/dotnet-90:latest AS build
WORKDIR /src

# ensure write permissions for dotnet (fix /src/obj permission issues)
USER root
RUN mkdir -p /src/obj /src/bin && chmod -R 0777 /src

# copy project + nuget config + local package registry
COPY Simulator.csproj ./
COPY nuget.config ./
COPY package-registry ./package-registry/

# register local package-registry so dotnet restore finds epay_dotnet_sdk
RUN dotnet nuget remove source local-reg || true
RUN dotnet nuget add source "/src/package-registry" -n local-reg || true
RUN dotnet nuget add source "https://api.nuget.org/v3/index.json" -n nuget-org || true

# debug listing of sources (visible in build logs)
RUN dotnet nuget list source

# restore using the registered local source
RUN dotnet restore Simulator.csproj

# copy remainder of source and publish
COPY . .
RUN dotnet publish Simulator.csproj -c Release -o /app/publish /p:UseAppHost=false

# ---------- Runtime stage ----------
FROM registry.dev.sbiepay.sbi:8443/ubi9/dotnet-90:latest AS runtime
WORKDIR /opt/app-root/app

COPY --from=build /app/publish/ ./

USER root
RUN chmod -R 755 /opt/app-root/app
USER 1001

ENV ASPNETCORE_URLS=http://+:5001
EXPOSE 5001

ENTRYPOINT ["dotnet", "Simulator.dll"]


frontend ____

FROM registry.dev.sbiepay.sbi:8443/ubi9/nginx-126:9.6-1756959223
USER 0
RUN mkdir -p /usr/share/nginx/html/merchantintegration
COPY ./ /usr/share/nginx/html/merchantintegration
RUN ls -lrth /usr/share/nginx/html/merchantintegration
RUN chmod 755 -R  /usr/share/nginx/html/merchantintegration
RUN chown -R nginx:nginx /usr/share/nginx/html/merchantintegration
COPY ./nginx.conf /etc/nginx/nginx.conf
RUN find /etc/nginx -type d | xargs chmod 750
RUN find /etc/nginx -type f | xargs chmod 640
EXPOSE 8080/tcp
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
