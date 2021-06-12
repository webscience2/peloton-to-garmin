FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build

COPY . /build
WORKDIR /build

SHELL ["/bin/bash", "-c"]

ARG TARGETPLATFORM
ARG VERSION

RUN echo $TARGETPLATFORM
RUN echo $VERSION
ENV VERSION=${VERSION}

RUN if [[ "$TARGETPLATFORM" = "linux/arm64" ]] ; then \
		dotnet publish /build/src/PelotonToGarminConsole/PelotonToGarminConsole.csproj -c Release -r linux-musl-arm64 -o /build/published --version-suffix $VERSION ; \
	else \
		dotnet publish /build/src/PelotonToGarminConsole/PelotonToGarminConsole.csproj -c Release -r linux-musl-x64 -o /build/published --version-suffix $VERSION ; \
	fi

FROM mcr.microsoft.com/dotnet/runtime:5.0-alpine

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache bash python3 tzdata && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools

RUN python --version
RUN pip3 --version

WORKDIR /app

COPY --from=build /build/published .
COPY --from=build /build/python/requirements.txt ./requirements.txt
COPY --from=build /build/LICENSE ./LICENSE
COPY --from=build /build/configuration.example.json ./configuration.local.json

RUN mkdir output
RUN mkdir working

RUN touch syncHistory.json
RUN echo "{}" >> syncHistory.json

RUN pip3 install -r requirements.txt

RUN ls -l
ENTRYPOINT ["./PelotonToGarminConsole"]