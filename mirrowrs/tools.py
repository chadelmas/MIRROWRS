# Copyright (C) 2024-2025 CS GROUP, https://csgroup.eu
#
# This file is part of MIRROWRS (Mapper to InfeR River Observations of Widths from Remote Sensing)
#
#     https://github.com/csgroup-oss/MIRROWRS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
tools.py
: module containing diverse python tools to follow execution
"""

import logging
import time

_logger = logging.getLogger("tools_module")

def _ogr_open_checked(path):
    """Open a vector file with ogr, raising if it is missing/unreadable or empty.

    ogr.Open returns None (without raising) when the file cannot be opened, so
    the None case must be checked explicitly instead of relying on a try/except
    around ogr.Open alone. /vsis3 paths also need the same GDAL S3 env as rasters.
    """

    if _is_vsis3_path(path):
        _warn_if_incomplete_s3_auth(path)
        with rio.Env(**_build_gdal_s3_env()):
            info = ogr.Open(path)
    else:
        info = ogr.Open(path)

    if info is None:
        raise FileExistsError(f"Input {path} file could not be read.")

    if info.GetLayer(0).GetFeatureCount() == 0:
        raise FileExistsError(f"Input {path} file contains no features.")

    return info
class FileExtensionError(TypeError):
    """Specific exception indicating a wrong file extension
    """
    def __init__(self, message="File has to have a different extension."):
        """Class constructor"""
        self.message = message
        super().__init__(self.message)


class DisjointBboxError(ValueError):
    """Specific exception indicating that two bounding boxes are disjoint
    """
    def __init__(self, message="Compared scenes do not overlap."):
        """Class constructor"""
        self.message = message
        super().__init__(self.message)


class DimensionError(ValueError):
    """Specific exception indicating the object does not have the right shape
    """
    def __init__(self, message="Object has the wrong dimensions."):
        """Class constructor"""
        self.message = message
        super().__init__(self.message)



