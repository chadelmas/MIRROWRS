"""Shared S3-aware path and GDAL opening helpers."""

import logging
import os
from contextlib import contextmanager

import geopandas as gpd
import rasterio as rio


_logger = logging.getLogger(__name__)


def is_s3_path(path):
    """Return whether a path uses an S3 URI or GDAL's S3 virtual filesystem."""

    path = os.fspath(path) if isinstance(path, os.PathLike) else path
    return isinstance(path, str) and path.startswith(("s3://", "/vsis3/"))


def normalize_s3_path(path):
    """Convert an ``s3://`` URI to GDAL's ``/vsis3/`` path format."""

    path = os.fspath(path) if isinstance(path, os.PathLike) else path
    if isinstance(path, str) and path.startswith("s3://"):
        return "/vsis3/" + path[len("s3://") :]
    return path


def build_gdal_s3_env():
    """Build GDAL options for S3 without copying credentials into GDAL config."""

    options = {}
    endpoint = os.environ.get("AWS_S3_ENDPOINT")
    if endpoint:
        options["AWS_S3_ENDPOINT"] = endpoint
        options["AWS_VIRTUAL_HOSTING"] = os.environ.get(
            "AWS_VIRTUAL_HOSTING", "FALSE"
        )
    elif os.environ.get("AWS_VIRTUAL_HOSTING"):
        options["AWS_VIRTUAL_HOSTING"] = os.environ["AWS_VIRTUAL_HOSTING"]

    ca_bundle = (
        os.environ.get("GDAL_HTTP_CAINFO")
        or os.environ.get("AWS_CA_BUNDLE")
        or os.environ.get("CURL_CA_BUNDLE")
        or os.environ.get("SSL_CERT_FILE")
    )
    if ca_bundle:
        options["GDAL_HTTP_CAINFO"] = ca_bundle

    return options


def _warn_if_incomplete_s3_auth(path):
    if not is_s3_path(path):
        return

    if not os.environ.get("AWS_ACCESS_KEY_ID") or not os.environ.get(
        "AWS_SECRET_ACCESS_KEY"
    ):
        _logger.warning(
            "S3 path detected without AWS_ACCESS_KEY_ID and/or "
            "AWS_SECRET_ACCESS_KEY in the process environment."
        )


@contextmanager
def open_raster(path, mode="r", **kwargs):
    """Open a local or S3 raster, keeping its GDAL environment active."""

    path = normalize_s3_path(path)
    if is_s3_path(path):
        _warn_if_incomplete_s3_auth(path)
        with rio.Env(**build_gdal_s3_env()):
            with rio.open(path, mode, **kwargs) as dataset:
                yield dataset
    else:
        with rio.open(path, mode, **kwargs) as dataset:
            yield dataset


def read_vector(path, **kwargs):
    """Read a local or S3 vector dataset as a GeoDataFrame.

    S3 reads use pyogrio explicitly so GDAL options are applied to the driver
    that performs the read. Credentials remain in the process environment.
    """

    path = normalize_s3_path(path)
    if is_s3_path(path):
        _warn_if_incomplete_s3_auth(path)
        options = build_gdal_s3_env()
        options.update(kwargs.pop("config_options", {}))
        kwargs.setdefault("engine", "pyogrio")
        return gpd.read_file(path, config_options=options, **kwargs)
    return gpd.read_file(path, **kwargs)