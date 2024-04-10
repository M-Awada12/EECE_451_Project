import React, { useState, useEffect } from "react";
import { NavLink } from "react-router-dom";
import "./NavBar.css";
import security from "../../img/security.png";

function NavBar() {
  const [click, setClick] = useState(false);

  const handleClick = () => setClick(!click);
  return (
    <>
      <nav className="navbar">
        <div className="nav-container">
          <NavLink exact to="/" className="nav-logo">
            <img id="logo-image" src={security} alt="logo" />
          </NavLink>
          <strong className="title-navbar">Mobile Network Analyzer</strong>

          <ul className={click ? "nav-menu active" : "nav-menu"}>
            <li className="nav-item">
              {/*<NavLink
                exact
                to="/"
                activeClassName="active"
                className="nav-links"
                onClick={handleClick}
              >
                Two Square Playfair Cipher
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink
                exact
                to="/hill-cipher"
                activeClassName="active"
                className="nav-links"
                onClick={handleClick}
              >
                Hill Cipher
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink
                exact
                to="/explanation"
                activeClassName="active"
                className="nav-links"
                onClick={handleClick}
              >
                Explanation
              </NavLink>*/}
            </li>
          </ul>
          <div className="nav-icon" onClick={handleClick}>
            <div
              className={
                click ? "navbar_toggle navbar_toggle_x" : "navbar_toggle"
              }
              onClick={handleClick}
            >
              <span></span>
              <span></span>
              <span></span>
            </div>
          </div>
        </div>
      </nav>
    </>
  );
}

export default NavBar;
