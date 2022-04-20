FROM golang:1.18-alpine AS build

WORKDIR /app
COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=0 go build -o ./admission-denier

FROM gcr.io/distroless/base-debian10
WORKDIR /app

COPY --from=build /app/admission-denier /admission-denier
EXPOSE 443
USER nonroot:nonroot

ENTRYPOINT ["/admission-denier"]
